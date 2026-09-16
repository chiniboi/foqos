import SwiftUI

/// The first thing you see: the mark over a world whose roads all run to one
/// point in Italy. Nothing says where it is; the lines just go there.
struct SplashView: View {
  var onFinished: () -> Void

  @State private var roadProgress: [CGFloat] = []
  @State private var markScale: CGFloat = 0.82
  @State private var markOpacity: CGFloat = 0
  @State private var haloScale: CGFloat = 0.6

  private let background = Color(hex: "#fbf8dd")
  private let land = Color(hex: "#3a7a33")
  private let road = Color(hex: "#2d3a2a")

  private let rome = WorldMapData.point(longitude: 12.5, latitude: 41.9)

  /// Where the roads start. Spread across the continents so the lines arrive
  /// from every direction.
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

  var body: some View {
    ZStack {
      background.ignoresSafeArea()

      GeometryReader { geometry in
        let frame = mapFrame(in: geometry.size)

        ZStack {
          coastlines(in: frame)

          roads(in: frame)

          destination(in: frame)
        }
      }
      .ignoresSafeArea()

      LokiLogo(size: 188)
        .scaleEffect(markScale)
        .opacity(markOpacity)
        .shadow(color: road.opacity(0.18), radius: 24, y: 10)
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: onFinished)
    .onAppear(perform: run)
  }

  private func coastlines(in frame: CGRect) -> some View {
    Path { path in
      for shape in WorldMapData.shapes {
        guard let first = shape.first else { continue }

        path.move(to: place(first, in: frame))
        for point in shape.dropFirst() {
          path.addLine(to: place(point, in: frame))
        }
        path.closeSubpath()
      }
    }
    .stroke(land.opacity(0.45), style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
  }

  private func roads(in frame: CGRect) -> some View {
    ForEach(origins.indices, id: \.self) { index in
      roadPath(from: origins[index], seed: index, in: frame)
        .trim(from: 0, to: progress(at: index))
        .stroke(
          road.opacity(0.7),
          style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
        )
    }
  }

  private func progress(at index: Int) -> CGFloat {
    index < roadProgress.count ? roadProgress[index] : 0
  }

  /// A road rather than a ruler line: it bows one way, wanders a little on the
  /// way, and still ends up in the same place.
  private func roadPath(from origin: CGPoint, seed: Int, in frame: CGRect) -> Path {
    let start = place(origin, in: frame)
    let end = place(rome, in: frame)
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = max(1, sqrt(dx * dx + dy * dy))
    let normal = CGPoint(x: -dy / length, y: dx / length)

    var generator = SeededGenerator(seed: UInt64(seed) &* 2_654_435_761 &+ 11)
    let bow = CGFloat.random(in: 0.1...0.22, using: &generator)
      * (Bool.random(using: &generator) ? 1 : -1)

    let segments = 7
    var points: [CGPoint] = [start]
    for step in 1..<segments {
      let t = CGFloat(step) / CGFloat(segments)
      let along = CGPoint(x: start.x + dx * t, y: start.y + dy * t)
      let arc = sin(t * .pi) * bow * length
      let wander = CGFloat.random(in: -0.045...0.045, using: &generator) * length
      let offset = arc + wander
      points.append(
        CGPoint(x: along.x + normal.x * offset, y: along.y + normal.y * offset)
      )
    }
    points.append(end)

    // round the corners off so the turns look driven rather than drawn
    var path = Path()
    path.move(to: points[0])
    for index in 1..<(points.count - 1) {
      let next = points[index + 1]
      let mid = CGPoint(x: (points[index].x + next.x) / 2, y: (points[index].y + next.y) / 2)
      path.addQuadCurve(to: mid, control: points[index])
    }
    path.addLine(to: points[points.count - 1])

    return path
  }

  private func destination(in frame: CGRect) -> some View {
    let point = place(rome, in: frame)

    return ZStack {
      Circle()
        .stroke(land.opacity(0.5), lineWidth: 1.2)
        .frame(width: 34, height: 34)
        .scaleEffect(haloScale)
        .opacity(Double(2 - haloScale))

      Circle()
        .fill(land)
        .frame(width: 7, height: 7)
    }
    .position(point)
    .opacity(Double(progress(at: 0)))
  }

  /// The map is equirectangular, so it wants a 2:1 box. It is sized to show
  /// most of the world and then shifted so Rome lands dead centre, under the
  /// mark, with every road arriving there.
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

  private func run() {
    guard roadProgress.isEmpty else { return }

    roadProgress = Array(repeating: 0, count: origins.count)

    // every road travels at its own pace, and they are all in before 2 seconds
    for index in origins.indices {
      let duration = 0.8 + Double(index % 5) * 0.22
      let delay = Double(index % 3) * 0.08

      withAnimation(.easeOut(duration: duration).delay(delay)) {
        roadProgress[index] = 1
      }
    }

    withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) {
      markScale = 1
      markOpacity = 1
    }

    withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false).delay(0.5)) {
      haloScale = 1.9
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
      onFinished()
    }
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
