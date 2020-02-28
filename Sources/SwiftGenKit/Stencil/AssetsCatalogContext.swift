//
// SwiftGenKit
// Copyright © 2019 SwiftGen
// MIT Licence
//

import Foundation

//
// See the documentation file for a full description of this context's structure:
// Documentation/SwiftGenKit Contexts/Assets.md
//

extension AssetsCatalog.Parser {
  public func stencilContext() -> [String: Any] {
    let catalogs = self.catalogs
      .sorted { lhs, rhs in lhs.name < rhs.name }
      .map { catalog -> [String: Any] in
        [
          "name": catalog.name,
          "assets": structure(entries: catalog.entries)
        ]
      }

    return [
      "catalogs": catalogs
    ]
  }

  private func structure(entries: [AssetsCatalog.Entry]) -> [[String: Any]] {
    // swiftlint:disable:next closure_body_length
    return entries.map { entry in
      switch entry {
      case .color(let name, let value, let metadata):
        return [
          "type": "color",
          "name": name,
          "value": value,
          "metadata": metadata
        ]
      case .data(let name, let value, let metadata):
        return [
          "type": "data",
          "name": name,
          "value": value,
          "metadata": metadata
        ]
      case .group(let name, let isNamespaced, let items, let metadata):
        return [
          "type": "group",
          "isNamespaced": "\(isNamespaced)",
          "name": name,
          "items": structure(entries: items),
          "metadata": metadata
        ]
      case .image(let name, let value, let metadata):
        return [
          "type": "image",
          "name": name,
          "value": value,
          "metadata": metadata
        ]
      }
    }
  }
}
