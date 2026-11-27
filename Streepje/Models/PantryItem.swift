import Foundation
import SwiftData
import SwiftUI

/// De zeven vaste categorieën van fase 1 (hercategoriseren via long-press komt in fase 3).
enum PantryCategory: String, CaseIterable, Codable, Identifiable {
    case grains
    case dairy
    case produce
    case canned
    case baking
    case snacks
    case household

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grains: return "Granen & Pasta"
        case .dairy: return "Zuivel & Eieren"
        case .produce: return "Groente & Fruit"
        case .canned: return "Conserven & Sauzen"
        case .baking: return "Kruiden & Bakken"
        case .snacks: return "Snacks & Snoep"
        case .household: return "Huishoudelijk & Verzorging"
        }
    }

    var icon: String {
        switch self {
        case .grains: return "takeoutbag.and.cup.and.straw"
        case .dairy: return "drop"
        case .produce: return "carrot"
        case .canned: return "cylinder.split.1x2"
        case .baking: return "birthday.cake"
        case .snacks: return "birthday.cake.fill"
        case .household: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .grains: return Color(red: 0.98, green: 0.80, blue: 0.28)
        case .dairy: return Color(red: 0.55, green: 0.75, blue: 0.98)
        case .produce: return Color(red: 0.42, green: 0.80, blue: 0.45)
        case .canned: return Color(red: 0.98, green: 0.60, blue: 0.28)
        case .baking: return Color(red: 0.70, green: 0.55, blue: 0.92)
        case .snacks: return Color(red: 0.96, green: 0.52, blue: 0.70)
        case .household: return Color(red: 0.28, green: 0.72, blue: 0.72)
        }
    }
}

/// Eén voorraadproduct in de voorraadkast.
///
/// Vereenvoudigd model volgens de review op issue #2: hoeveelheden in stuks/verpakkingen
/// (geen percentages), drempel ("ijzeren voorraad") in stuks, en één "aangebroken"-vlag
/// in plaats van een percentuele slider.
///
/// Let op: `.unique` op barcode is handig op één apparaat, maar werkt niet samen met
/// CloudKit-synchronisatie (fase 5) — bij die migratie vervalt dit attribuut.
@Model
final class PantryItem {
    @Attribute(.unique) var barcode: String
    var name: String = ""
    var categoryRaw: String = PantryCategory.household.rawValue
    /// Aantal verpakkingen op voorraad (0 = op).
    var quantity: Int = 0
    /// Er is één verpakking aangebroken.
    var isOpen: Bool = false
    /// IJzeren voorraad: bij `quantity <= threshold` komt het product op de boodschappenlijst.
    var threshold: Int = 1
    /// Standaard aanvulhoeveelheid waarnaar "Aanvullen in voorraad" reset.
    var defaultStock: Int = 1
    /// Moment waarop de voorraad onder de drempel zakte (voor "waarom"-labels).
    var lowSince: Date?
    var createdAt: Date = Date()

    init(barcode: String,
         name: String,
         category: PantryCategory = .household,
         quantity: Int = 0,
         isOpen: Bool = false,
         threshold: Int = 1,
         defaultStock: Int = 1,
         lowSince: Date? = nil,
         createdAt: Date = Date()) {
        self.barcode = barcode
        self.name = name
        self.categoryRaw = category.rawValue
        self.quantity = quantity
        self.isOpen = isOpen
        self.threshold = threshold
        self.defaultStock = defaultStock
        self.lowSince = lowSince
        self.createdAt = createdAt
    }

    var category: PantryCategory {
        get { PantryCategory(rawValue: categoryRaw) ?? .household }
        set { categoryRaw = newValue.rawValue }
    }

    /// Staat de voorraad op of onder de ijzeren voorraad?
    var isLow: Bool { quantity <= threshold }
}
