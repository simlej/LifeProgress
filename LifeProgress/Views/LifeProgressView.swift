import SwiftUI

struct LifeProgressView: View {
    let life: Life
    var displayMode: DisplayMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Most of the calendar is drawn using canvas,
            // except for the current year
            //
            // We're doing this because when switching from `life` to `year` mode,
            // the cells from the current year should transition smoothly to
            // a new grid layout.
            // This is really easy with view transitions, I'm not sure if it's possible
            // to do with canvas only.
            calendarWithoutCurrentYear

            // Draw the current year with views
            currentYear
        }
        .aspectRatio(
            Double(Life.totalWeeksInAYear) / Double(life.lifeExpectancy),
            contentMode: .fit
        )
    }

    var calendarWithoutCurrentYear: some View {
        Canvas { context, size in
            let containerWidth = size.width
            let cellSize = containerWidth / Double(Life.totalWeeksInAYear)
            let cellPadding = cellSize / 12

            for yearIndex in 0 ..< life.lifeExpectancy {
                for weekIndex in 0 ..< Life.totalWeeksInAYear {
                    let cellPath =
                        Path(CGRect(
                            x: Double(weekIndex) * cellSize + cellPadding,
                            y: Double(yearIndex) * cellSize + cellPadding,
                            width: cellSize - cellPadding * 2,
                            height: cellSize - cellPadding * 2
                        ))

                    let currentYear = yearIndex + 1
                    let ageGroupColor = AgeGroup(age: currentYear)
                        .getColor()

                    // Ignore the current year (currentYear == life.age)
                    if currentYear < life.age {
                        context.fill(cellPath, with: .color(ageGroupColor))
                    } else if currentYear > life.age {
                        context.fill(
                            cellPath,
                            with: .color(Color(uiColor: .systemFill))
                        )
                    }
                }
            }
        }
        .opacity(displayMode == .life ? 1 : 0)
        .animation(
            getAnimation(isActive: displayMode == .life),
            value: displayMode
        )
    }

    var currentYear: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let currentYearModeColumnCount = 6

            let cellSize = displayMode == .currentYear ?
                containerWidth / Double(currentYearModeColumnCount) :
                containerWidth / Double(Life.totalWeeksInAYear)
            let cellPadding = cellSize / 12

            ForEach(0 ..< Life.totalWeeksInAYear, id: \.self) { weekIndex in
                // TODO: Maybe instead of doing it this way, I could just lay things out normally
                // and use matchedGeometryEffect and let SwiftUI do its "magic move" thing
                let rowIndex = displayMode == .currentYear ?
                    weekIndex / currentYearModeColumnCount :
                    life.age - 1
                let columnIndex = displayMode == .currentYear ?
                    weekIndex % currentYearModeColumnCount :
                    weekIndex

                Rectangle()
                    .fill(weekIndex < life.weekOfYear ?
                        AgeGroup(age: life.age + 1).getColor() :
                        Color(uiColor: .systemFill))
                    .padding(cellPadding)
                    .frame(width: cellSize, height: cellSize)
                    .offset(
                        x: Double(columnIndex) * cellSize,
                        y: Double(rowIndex) * cellSize
                    )
                    .animation(
                        getAnimation(isActive: displayMode == .currentYear)
                            .delay(Double(weekIndex / currentYearModeColumnCount) * 0.04),
                        value: displayMode
                    )
            }
        }
    }

    enum DisplayMode {
        case currentYear
        case life
    }

    func getAnimation(isActive: Bool) -> Animation {
        let animation = Animation.easeInOut(duration: 0.4)

        if isActive {
            return animation.delay(0.4)
        }

        return animation
    }
}

struct LifeCalendar_Previews: PreviewProvider {
    static var previews: some View {
        LifeProgressView(life: Life.example, displayMode: .life)
    }
}
