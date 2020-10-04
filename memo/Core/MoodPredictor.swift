import Foundation
import NaturalLanguage

final class MoodPredictor {

    private let neutralMood: Int8 = 2
    private let model: NLModel

    init(model: NLModel) {
        self.model = model
    }

    func mood(text: String) -> Int8 {
        let predictedLabel = model.predictedLabel(for: text)

        switch predictedLabel {
        case "negative":
            return 0
        case "neutral":
            return neutralMood
        case "positive":
            return 4
        default:
            return neutralMood
        }
    }
}
