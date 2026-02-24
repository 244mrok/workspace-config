import Foundation

extension Double {
    var weightString: String {
        String(format: "%.1f", self)
    }

    var bodyFatString: String {
        String(format: "%.1f", self)
    }

    var bmiString: String {
        String(format: "%.1f", self)
    }

    var weightWithUnit: String {
        "\(weightString) kg"
    }

    var bodyFatWithUnit: String {
        "\(bodyFatString) %"
    }

    var bmiWithUnit: String {
        "BMI \(bmiString)"
    }

    var signedString: String {
        if self > 0 {
            return "+\(String(format: "%.1f", self))"
        }
        return String(format: "%.1f", self)
    }
}
