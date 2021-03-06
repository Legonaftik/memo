import UIKit

protocol DatePickerViewControllerDelegate: AnyObject {
    func datePicker(_ datePicker: DatePickerViewController, didSelect date: Date)
}

final class DatePickerViewController: UIViewController {

    weak var delegate: DatePickerViewControllerDelegate?

    @IBOutlet private var datePicker: UIDatePicker!

    @IBAction private func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction private func done(_ sender: UIBarButtonItem) {
        delegate?.datePicker(self, didSelect: datePicker.date)
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker.maximumDate = Date()
    }
}
