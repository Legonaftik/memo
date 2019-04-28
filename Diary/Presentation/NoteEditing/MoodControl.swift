//
//  MoodControl.swift
//  Diary
//
//  Created by Vladimir Pavlov on 11/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class MoodControl: UIControl {

  var selectedSegmentIndex = 2 {
    didSet { self.setNeedsDisplay() }
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
      self.addSubview(button)

      button.translatesAutoresizingMaskIntoConstraints = false
      button.widthAnchor.constraint(equalToConstant: circleDiameter).isActive = true
      button.heightAnchor.constraint(equalToConstant: circleDiameter).isActive = true

      button.layer.cornerRadius = self.circleDiameter / 2
      button.layer.borderColor = UIColor.gray.cgColor
      button.backgroundColor = self.moodColors[index]
      button.addTarget(self, action: #selector(selectMood(selectedButton:)), for: .touchUpInside)

      self.buttons.append(button)
    }

    self.moveButtonsInStack()

    self.backgroundColor = .clear
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)

    for (index, button) in self.buttons.enumerated() {
      button.layer.borderWidth = 0
      if index == self.selectedSegmentIndex {
        button.layer.borderWidth = self.selectedMoodBorderWidth
      }
    }
  }

  // MARK: - Helpers

  private func moveButtonsInStack() {
    let stackView = UIStackView(arrangedSubviews: self.buttons)
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .equalSpacing
    self.addSubview(stackView)

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
    stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
  }

  @objc private func selectMood(selectedButton: UIButton) {
    for (index, button) in self.buttons.enumerated() where button == selectedButton {
        self.selectedSegmentIndex = index
    }
  }
}
