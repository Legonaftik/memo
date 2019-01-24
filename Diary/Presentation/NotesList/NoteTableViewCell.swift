//
//  NoteTableViewCell.swift
//  Diary
//
//  Created by Vladimir Pavlov on 04/10/2017.
//  Copyright © 2017 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class NoteTableViewCell: UITableViewCell {

  @IBOutlet private var containerView: UIView!
  @IBOutlet private var dateLabel: UILabel!
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var photoImageView: UIImageView!
  @IBOutlet private var contentLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    setRoundedCornersWithShadow()
  }

  private func setRoundedCornersWithShadow() {
    containerView.layer.cornerRadius = 8
    containerView.layer.masksToBounds = false
    containerView.layer.shadowOffset = CGSize(width: 3, height: 3)
    containerView.layer.shadowRadius = 4
    containerView.layer.shadowOpacity = 0.3
  }
}

extension NoteTableViewCell {

  /// This method uses IUOs IBOutlets to access the cell's subviews.
  /// The subviews should only be accessed if the content which they represent is present.
  /// E.g. don't access UIImageView unless the note has an image.
  ///
  /// - Parameter note: Note model object which is used to configure cell.
  func configure(with note: Note) {
    containerView.alpha = note.isSynced ? 1.0 : 0.5

    dateLabel.text = dateFormatter.string(from: note.creationDate)

    if let title = note.title, !title.isEmpty {
      titleLabel.text = title
    }

    if let content = note.content, !content.isEmpty {
      contentLabel.text = note.content
    }

    if let image = note.image, let jpegData = image.jpegData {
      photoImageView.image = UIImage(data: jpegData)
    }
  }

  func setImage(with data: Data) {
    photoImageView.image = UIImage(data: data)
  }
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .full
  return formatter
}()
