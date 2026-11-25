import Foundation

enum ProductLookup {
    private static let cacheKey = "streepje.productCache"
    private static let userAgent = "Streepje/1.0 (iOS; +https://github.com/pbijkerk/streepje)"

    static func cachedName(for barcode: String) -> String? {
        cache()[barcode]
    }

    static func name(for barcode: String) async -> String? {
        var productCache = cache()
        if let cached = productCache[barcode] { return cached }

        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let payload = try JSONDecoder().decode(OFFResponse.self, from: data)
            guard payload.status == 1, let product = payload.product else { return nil }
            let name = product.bestName
            guard let name, !name.isEmpty else { return nil }
            productCache[barcode] = name
            save(productCache)
            return name
        } catch {
            return nil
        }
    }

    private struct OFFResponse: Decodable {
        let status: Int?
        let product: OFFProduct?
    }

    private struct OFFProduct: Decodable {
        let productName: String?
        let productNameNl: String?
        let brands: String?
        let genericName: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case productNameNl = "product_name_nl"
            case brands
            case genericName = "generic_name"
        }

        var bestName: String? {
            [productNameNl, productName, brands, genericName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
        }
    }

    private static func cache() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    private static func save(_ cache: [String: String]) {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
