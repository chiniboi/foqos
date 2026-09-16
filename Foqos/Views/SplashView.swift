import SwiftUI

/// The first thing you see: a quiet map whose roads all run to one point in
/// Italy. Nothing says where that is; the roads simply go there.
struct SplashView: View {
  var onFinished: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  @State private var roadProgress: [CGFloat] = []
  @State private var pulse: CGFloat = 0.4
  @State private var mapOpacity: CGFloat = 0

  private let rome = WorldMapData.point(longitude: 12.5, latitude: 41.9)

  /// Where the roads set out from. Spread wide so they arrive from every side.
  private let origins: [CGPoint] = [
    WorldMapData.point(longitude: -123.1, latitude: 49.3),  // Vancouver
    WorldMapData.point(longitude: -74.0, latitude: 40.7),  // New York
    WorldMapData.point(longitude: -58.4, latitude: -34.6),  // Buenos Aires
    WorldMapData.point(longitude: -9.1, latitude: 38.7),  // Lisbon
    WorldMapData.point(longitude: 18.4, latitude: -33.9),  // Cape Town
    WorldMapData.point(longitude: 36.8, latitude: -1.3),  // Nairobi
    WorldMapData.point(longitude: 37.6, latitude: 55.8),  // Moscow
    WorldMapData.point(longitude: 72.8, latitude: 19.1),  // Mumbai
    WorldMapData.point(longitude: 116.4, latitude: 39.9),  // Beijing
    WorldMapData.point(longitude: 139.7, latitude: 35.7),  // Tokyo
    WorldMapData.point(longitude: 151.2, latitude: -33.9),  // Sydney
  ]

  private var palette: Palette { colorScheme == .dark ? .night : .day }

  var body: some View {
    ZStack {
      palette.paper.ignoresSafeArea()

      GeometryReader { geometry in
        let frame = mapFrame(in: geometry.size)

        ZStack {
          graticule(in: frame)

          land(in: frame)

          roads(in: frame)

          destination(in: frame)
        }
        .opacity(Double(mapOpacity))
      }
      .ignoresSafeArea()
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: onFinished)
    .onAppear(perform: run)
  }

  // MARK: - Layers

  /// Meridians and parallels every 20 degrees: enough to read as a chart
  /// rather than a doodle.
  private func graticule(in frame: CGRect) -> some View {
    Path { path in
      for longitude in stride(from: -180.0, through: 180.0, by: 20.0) {
        let top = place(WorldMapData.point(longitude: longitude, latitude: 90), in: frame)
        let bottom = place(WorldMapData.point(longitude: longitude, latitude: -90), in: frame)
        path.move(to: top)
        path.addLine(to: bottom)
      }

      for latitude in stride(from: -80.0, through: 80.0, by: 20.0) {
        let left = place(WorldMapData.point(longitude: -180, latitude: latitude), in: frame)
        let right = place(WorldMapData.point(longitude: 180, latitude: latitude), in: frame)
        path.move(to: left)
        path.addLine(to: right)
      }
    }
    .stroke(palette.grid, lineWidth: 0.6)
  }

  private func land(in frame: CGRect) -> some View {
    let shape = Path { path in
      for coastline in WorldMapData.shapes {
        guard let first = coastline.first else { continue }

        path.move(to: place(first, in: frame))
        for point in coastline.dropFirst() {
          path.addLine(to: place(point, in: frame))
        }
        path.closeSubpath()
      }
    }

    return ZStack {
      shape.fill(palette.land)
      shape.stroke(palette.coast, style: StrokeStyle(lineWidth: 0.7, lineJoin: .round))
    }
  }

  private func roads(in frame: CGRect) -> some View {
    ForEach(origins.indices, id: \.self) { index in
      let path = roadPath(from: origins[index], seed: index, in: frame)
      let progress = progress(at: index)

      ZStack {
        // a soft underlay so the road reads against the coastlines
        path
          .trim(from: 0, to: progress)
          .stroke(
            palette.roadGlow,
            style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
          )

        path
          .trim(from: 0, to: progress)
          .stroke(
            palette.road,
            style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
          )
      }
    }
  }

  private func destination(in frame: CGRect) -> some View {
    let point = place(rome, in: frame)
    let arrived = progress(at: 0)

    return ZStack {
      Circle()
        .stroke(palette.road.opacity(0.45), lineWidth: 1)
        .frame(width: 46, height: 46)
        .scaleEffect(pulse)
        .opacity(Double(1.5 - pulse))

      Circle()
        .stroke(palette.road.opacity(0.7), lineWidth: 1.2)
        .frame(width: 13, height: 13)

      Circle()
        .fill(palette.marker)
        .frame(width: 5.5, height: 5.5)
    }
    .position(point)
    .opacity(Double(arrived))
  }

  // MARK: - Geometry

  /// Equirectangular wants a 2:1 box. Size it to show most of the world, then
  /// shift it so Rome sits dead centre.
  private func mapFrame(in size: CGSize) -> CGRect {
    let width = size.width * 3.0
    let height = width / 2

    return CGRect(
      x: size.width / 2 - rome.x * width,
      y: size.height / 2 - rome.y * height,
      width: width,
      height: height
    )
  }

  private func place(_ point: CGPoint, in frame: CGRect) -> CGPoint {
    CGPoint(
      x: frame.minX + point.x * frame.width,
      y: frame.minY + point.y * frame.height
    )
  }

  private func progress(at index: Int) -> CGFloat {
    index < roadProgress.count ? roadProgress[index] : 0
  }

  /// A long route rather than a ruled line: it leaves at its own angle, bends
  /// once across the middle, and straightens as it arrives.
  private func roadPath(from origin: CGPoint, seed: Int, in frame: CGRect) -> Path {
    let start = place(origin, in: frame)
    let end = place(rome, in: frame)
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = max(1, sqrt(dx * dx + dy * dy))
    let normal = CGPoint(x: -dy / length, y: dx / length)

    var generator = SeededGenerator(seed: UInt64(seed) &* 2_654_435_761 &+ 11)
    let bow = CGFloat.random(in: 0.08...0.16, using: &generator)
      * (Bool.random(using: &generator) ? 1 : -1)
    let lean = CGFloat.random(in: 0.3...0.7, using: &generator)

    // one long arc, weighted towards one end, so the curve looks travelled
    let first = CGPoint(
      x: start.x + dx * lean * 0.6 + normal.x * bow * length,
      y: start.y + dy * lean * 0.6 + normal.y * bow * length
    )
    let second = CGPoint(
      x: start.x + dx * (0.55 + lean * 0.3) + normal.x * bow * length * 0.55,
      y: start.y + dy * (0.55 + lean * 0.3) + normal.y * bow * length * 0.55
    )

    var path = Path()
    path.move(to: start)
    path.addCurve(to: end, control1: first, control2: second)

    return path
  }

  private func run() {
    guard roadProgress.isEmpty else { return }

    roadProgress = Array(repeating: 0, count: origins.count)

    withAnimation(.easeOut(duration: 0.5)) {
      mapOpacity = 1
    }

    // each road travels at its own pace, all of them in before two seconds
    for index in origins.indices {
      let duration = 0.85 + Double(index % 5) * 0.2
      let delay = Double(index % 4) * 0.07

      withAnimation(.easeInOut(duration: duration).delay(delay)) {
        roadProgress[index] = 1
      }
    }

    withAnimation(.easeOut(duration: 1.7).repeatForever(autoreverses: false).delay(0.6)) {
      pulse = 1.6
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
      onFinished()
    }
  }
}

// MARK: - Colours

extension SplashView {
  /// Map colours for each appearance: paper and ink by day, a chart lit from
  /// behind at night.
  fileprivate struct Palette {
    let paper: Color
    let land: Color
    let coast: Color
    let grid: Color
    let road: Color
    let roadGlow: Color
    let marker: Color

    static let day = Palette(
      paper: Color(hex: "#f7f5e6"),
      land: Color(hex: "#3a7a33").opacity(0.09),
      coast: Color(hex: "#3a7a33").opacity(0.55),
      grid: Color(hex: "#3a7a33").opacity(0.1),
      road: Color(hex: "#2d3a2a").opacity(0.75),
      roadGlow: Color(hex: "#a3ec06").opacity(0.3),
      marker: Color(hex: "#2d3a2a")
    )

    static let night = Palette(
      paper: Color(hex: "#10150f"),
      land: Color(hex: "#8ad44b").opacity(0.07),
      coast: Color(hex: "#8ad44b").opacity(0.4),
      grid: Color(hex: "#8ad44b").opacity(0.08),
      road: Color(hex: "#a3ec06").opacity(0.8),
      roadGlow: Color(hex: "#a3ec06").opacity(0.18),
      marker: Color(hex: "#ffdd1e")
    )
  }
}

/// Small deterministic generator so a road looks the same every launch.
private struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
  }

  mutating func next() -> UInt64 {
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return state
  }
}

#Preview {
  SplashView(onFinished: {})
}

#Preview("Dark") {
  SplashView(onFinished: {})
    .preferredColorScheme(.dark)
}
