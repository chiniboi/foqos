import SwiftUI

/// The Loki mark: a lean rabbit holding a pocket watch, and none too happy
/// about what it says. Drawn rather than shipped as an image so it stays sharp
/// at any size and can be recoloured.
struct LokiLogo: View {
  var size: CGFloat = 120
  var outline: Color = Color(hex: "#2d3a2a")
  var fur: Color = Color(hex: "#fdfcf3")
  var accent: Color = Color(hex: "#3a7a33")
  var highlight: Color = Color(hex: "#a3ec06")

  /// Everything is drawn in a 100 x 100 grid and scaled from there.
  private let grid: CGFloat = 100

  var body: some View {
    Canvas { context, _ in
      let scale = size / grid
      context.scaleBy(x: scale, y: scale)

      drawEar(in: &context, centre: CGPoint(x: 31, y: 21), angle: .degrees(-11))
      drawEar(in: &context, centre: CGPoint(x: 45, y: 18), angle: .degrees(9))
      drawBody(in: &context)
      drawHead(in: &context)
      drawArm(in: &context)
      drawWatch(in: &context)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  private func drawEar(
    in context: inout GraphicsContext,
    centre: CGPoint,
    angle: Angle
  ) {
    var transform = CGAffineTransform(translationX: centre.x, y: centre.y)
    transform = transform.rotated(by: angle.radians)

    let outer = Path(ellipseIn: CGRect(x: -4.6, y: -18, width: 9.2, height: 36))
      .applying(transform)
    let inner = Path(ellipseIn: CGRect(x: -1.9, y: -12, width: 3.8, height: 24))
      .applying(transform)

    context.fill(outer, with: .color(fur))
    context.stroke(outer, with: .color(outline), lineWidth: 2.8)
    context.fill(inner, with: .color(highlight.opacity(0.5)))
  }

  private func drawBody(in context: inout GraphicsContext) {
    var body = Path()
    body.move(to: CGPoint(x: 32, y: 60))
    body.addCurve(
      to: CGPoint(x: 30, y: 88),
      control1: CGPoint(x: 27, y: 70),
      control2: CGPoint(x: 27, y: 82)
    )
    body.addCurve(
      to: CGPoint(x: 50, y: 88),
      control1: CGPoint(x: 34, y: 94),
      control2: CGPoint(x: 46, y: 94)
    )
    body.addCurve(
      to: CGPoint(x: 48, y: 60),
      control1: CGPoint(x: 53, y: 82),
      control2: CGPoint(x: 53, y: 70)
    )
    body.closeSubpath()

    context.fill(body, with: .color(fur))
    context.stroke(body, with: .color(outline), lineWidth: 2.8)

    for x in [34.0, 45.0] as [CGFloat] {
      let foot = Path(ellipseIn: CGRect(x: x - 5, y: 86, width: 10, height: 6))
      context.fill(foot, with: .color(fur))
      context.stroke(foot, with: .color(outline), lineWidth: 2.4)
    }
  }

  private func drawHead(in context: inout GraphicsContext) {
    let head = Path(ellipseIn: CGRect(x: 25, y: 33, width: 27, height: 30))
    context.fill(head, with: .color(fur))
    context.stroke(head, with: .color(outline), lineWidth: 2.8)

    // eyes, sitting high and small so the brows can do the work
    for x in [33.5, 44.0] as [CGFloat] {
      let eye = Path(ellipseIn: CGRect(x: x - 2.2, y: 44, width: 4.4, height: 5))
      context.fill(eye, with: .color(outline))
    }

    // brows tilted up towards the middle: the whole worry lives here
    drawStroke(
      in: &context,
      from: CGPoint(x: 29.5, y: 41.5),
      to: CGPoint(x: 36, y: 39),
      width: 2.2
    )
    drawStroke(
      in: &context,
      from: CGPoint(x: 41.5, y: 39),
      to: CGPoint(x: 48, y: 41.5),
      width: 2.2
    )

    var nose = Path()
    nose.move(to: CGPoint(x: 36.5, y: 52.5))
    nose.addLine(to: CGPoint(x: 41, y: 52.5))
    nose.addLine(to: CGPoint(x: 38.75, y: 55))
    nose.closeSubpath()
    context.fill(nose, with: .color(accent))

    // a small frown
    var mouth = Path()
    mouth.move(to: CGPoint(x: 34.5, y: 60))
    mouth.addQuadCurve(
      to: CGPoint(x: 43, y: 60),
      control: CGPoint(x: 38.75, y: 55.5)
    )
    context.stroke(
      mouth,
      with: .color(outline),
      style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
    )
  }

  private func drawArm(in context: inout GraphicsContext) {
    var arm = Path()
    arm.move(to: CGPoint(x: 48, y: 66))
    arm.addQuadCurve(
      to: CGPoint(x: 62, y: 60),
      control: CGPoint(x: 57, y: 68)
    )
    context.stroke(
      arm,
      with: .color(outline),
      style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
    )

    let paw = Path(ellipseIn: CGRect(x: 59, y: 55.5, width: 9, height: 9))
    context.fill(paw, with: .color(fur))
    context.stroke(paw, with: .color(outline), lineWidth: 2.6)
  }

  private func drawWatch(in context: inout GraphicsContext) {
    let centre = CGPoint(x: 74, y: 76)
    let radius: CGFloat = 12.5

    // chain from the paw down to the watch
    var chain = Path()
    chain.move(to: CGPoint(x: 64, y: 62))
    chain.addQuadCurve(
      to: CGPoint(x: 74, y: 61),
      control: CGPoint(x: 70, y: 57)
    )
    context.stroke(
      chain,
      with: .color(outline),
      style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [2.4, 2.2])
    )

    let ring = Path(ellipseIn: CGRect(x: 70.5, y: 58, width: 7, height: 6.5))
    context.stroke(ring, with: .color(outline), lineWidth: 2.2)

    let stem = Path(roundedRect: CGRect(x: 71.5, y: 62, width: 5, height: 4), cornerRadius: 1.4)
    context.fill(stem, with: .color(fur))
    context.stroke(stem, with: .color(outline), lineWidth: 2)

    let body = Path(
      ellipseIn: CGRect(
        x: centre.x - radius,
        y: centre.y - radius,
        width: radius * 2,
        height: radius * 2
      )
    )
    context.fill(body, with: .color(fur))
    context.stroke(body, with: .color(outline), lineWidth: 2.8)

    for hour in 0..<4 {
      let angle = Angle.degrees(Double(hour) * 90 - 90).radians
      drawStroke(
        in: &context,
        from: CGPoint(
          x: centre.x + cos(angle) * 6.5,
          y: centre.y + sin(angle) * 6.5
        ),
        to: CGPoint(
          x: centre.x + cos(angle) * 8.6,
          y: centre.y + sin(angle) * 8.6
        ),
        width: 1.6
      )
    }

    // five to midnight, which is the whole point of the rabbit's face
    drawStroke(in: &context, from: centre, to: CGPoint(x: centre.x - 4, y: centre.y - 6), width: 2.2)
    drawStroke(in: &context, from: centre, to: CGPoint(x: centre.x + 1, y: centre.y - 8), width: 2.2)

    let pin = Path(ellipseIn: CGRect(x: centre.x - 1.6, y: centre.y - 1.6, width: 3.2, height: 3.2))
    context.fill(pin, with: .color(accent))
  }

  private func drawStroke(
    in context: inout GraphicsContext,
    from start: CGPoint,
    to end: CGPoint,
    width: CGFloat
  ) {
    var path = Path()
    path.move(to: start)
    path.addLine(to: end)
    context.stroke(
      path,
      with: .color(outline),
      style: StrokeStyle(lineWidth: width, lineCap: .round)
    )
  }
}

#Preview {
  VStack(spacing: 30) {
    LokiLogo(size: 200)
    LokiLogo(size: 64)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color(hex: "#fbf8dd"))
}
