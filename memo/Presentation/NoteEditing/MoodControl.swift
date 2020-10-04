import UIKit

final class MoodControl: UIControl {

    var selectedSegmentIndex = 2 {
        didSet {
            setNeedsDisplay()
        }
    }

    private let numberOfMoods = 5
    private let moodColors: [UIColor] = [R.color.mood0()!,
                                         R.color.mood1()!,
                                         R.color.mood2()!,
                                         R.color.mood3()!,
                                         R.color.mood4()!]
    private let selectedMoodBorderWidth: CGFloat = 2
    private let circleDiameter: CGFloat = 35

    private var buttons = [UIButton]()

    override func awakeFromNib() {
        super.awakeFromNib()

        for index in 0..<numberOfMoods {
            let button = UIButton(type: .system)
            addSubview(button)

            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: circleDiameter).isActive = true
            button.heightAnchor.constraint(equalToConstant: circleDiameter).isActive = true

            button.layer.cornerRadius = circleDiameter / 2
            button.layer.borderColor = UIColor.secondarySystemBackground.cgColor
            button.backgroundColor = moodColors[index]
            button.addTarget(self, action: #selector(selectMood(selectedButton:)), for: .touchUpInside)

            buttons.append(button)
        }

        moveButtonsInStack()

        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        for (index, button) in buttons.enumerated() {
            button.layer.borderWidth = 0
            if index == selectedSegmentIndex {
                button.layer.borderWidth = selectedMoodBorderWidth
            }
        }
    }

    // MARK: - Helpers

    private func moveButtonsInStack() {
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc private func selectMood(selectedButton: UIButton) {
        for (index, button) in buttons.enumerated() where button == selectedButton {
            selectedSegmentIndex = index
        }
    }
}
