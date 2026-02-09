import XCTest

final class CardDragUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// Test rapid card dragging to stress test for card loss
    func testRapidCardDragging() throws {
        // Play multiple games with random drags
        for gameNum in 1...10 {
            print("🎮 Starting game \(gameNum)")
            
            // Tap "New" to start fresh game
            let newButton = app.buttons["New"]
            if newButton.exists {
                newButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            // Perform random drags
            for moveNum in 1...50 {
                performRandomDrag()
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            print("   Completed \(50) moves")
        }
    }
    
    /// Test dragging from waste pile
    func testWastePileDrags() throws {
        // Draw some cards first
        let stockArea = app.otherElements["stock"]
        if stockArea.exists {
            for _ in 1...5 {
                stockArea.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
        
        // Now try dragging from waste
        for _ in 1...20 {
            performRandomDrag()
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
    
    /// Test flick gestures
    func testFlickGestures() throws {
        // Draw a card
        tapStockPile()
        Thread.sleep(forTimeInterval: 0.3)
        
        // Try flicking in various directions
        let waste = app.otherElements["waste"]
        if waste.exists {
            // Flick up (to foundation)
            waste.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
            
            // Draw again
            tapStockPile()
            Thread.sleep(forTimeInterval: 0.3)
            
            // Flick right (to tableau)
            waste.swipeRight()
            Thread.sleep(forTimeInterval: 0.3)
        }
    }
    
    /// Test interrupted drags (start drag, then tap elsewhere)
    func testInterruptedDrags() throws {
        for _ in 1...10 {
            // Start a drag on tableau
            let screenCenter = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            let nearby = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            
            // Quick partial drag
            screenCenter.press(forDuration: 0.1, thenDragTo: nearby)
            Thread.sleep(forTimeInterval: 0.2)
            
            // Tap elsewhere to potentially interrupt
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).tap()
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
    
    /// Stress test: rapid taps and drags
    func testStressRapidInteractions() throws {
        for _ in 1...100 {
            let action = Int.random(in: 0...3)
            
            switch action {
            case 0:
                // Tap stock
                tapStockPile()
            case 1:
                // Random tap
                let x = CGFloat.random(in: 0.1...0.9)
                let y = CGFloat.random(in: 0.3...0.8)
                app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            case 2:
                // Random drag
                performRandomDrag()
            case 3:
                // Random swipe
                let x = CGFloat.random(in: 0.2...0.8)
                let y = CGFloat.random(in: 0.4...0.7)
                let coord = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
                let directions = ["up", "down", "left", "right"]
                switch directions.randomElement()! {
                case "up": coord.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y - 0.2)))
                case "down": coord.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y + 0.2)))
                case "left": coord.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: x - 0.2, dy: y)))
                case "right": coord.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: x + 0.2, dy: y)))
                default: break
                }
            default:
                break
            }
            
            Thread.sleep(forTimeInterval: 0.05)
        }
    }
    
    // MARK: - Helpers
    
    private func tapStockPile() {
        // Stock is in top-left area
        let stockCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.07, dy: 0.18))
        stockCoord.tap()
    }
    
    private func performRandomDrag() {
        // Random start position (in tableau area)
        let startX = CGFloat.random(in: 0.1...0.9)
        let startY = CGFloat.random(in: 0.35...0.85)
        
        // Random end position
        let endX = CGFloat.random(in: 0.1...0.9)
        let endY = CGFloat.random(in: 0.2...0.85)
        
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: startY))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: endY))
        
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
