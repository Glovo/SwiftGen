//
// SwiftGenKit
// Copyright © 2019 SwiftGen
// MIT Licence
//

import Foundation
import PathKit

extension AssetsCatalog {
  enum Entry {
    case color(name: String, value: String, metadata: [String: Any])
    case data(name: String, value: String, metadata: [String: Any])
    case group(name: String, isNamespaced: Bool, items: [Entry], metadata: [String: Any])
    case image(name: String, value: String, metadata: [String: Any])
  }
}

// MARK: - Parser

private enum Constants {
  static let path = "Contents.json"
  static let properties = "properties"
  static let providesNamespace = "provides-namespace"

  /**
   * This is a list of supported asset catalog item types, for now we just
   * support `color set`s, `image set`s and `data set`s. If you want to add support for
   * new types, just add it to this whitelist, and add the necessary code to
   * the `process(folder:withPrefix:)` method.
   *
   * Use as reference:
   * https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format
   */
  enum Item: String {
    case colorSet = "colorset"
    case dataSet = "dataset"
    case imageSet = "imageset"
  }
}

extension AssetsCatalog.Entry {
  /**
   Each node in an asset catalog is either (there are more types, but we ignore those):
     - A colorset, which is essentially a group containing a list of colors (the latter is ignored).
     - A dataset, which is essentially a group containing a list of files (the latter is ignored).
     - An imageset, which is essentially a group containing a list of files (the latter is ignored).
     - A group, containing sub items such as imagesets or groups. A group can provide a namespaced,
       which means that all the sub items will have to be prefixed with their parent's name.

         {
           "properties" : {
             "provides-namespace" : true
           }
         }

   - Parameter path: The directory path to recursively process.
   - Parameter prefix: The prefix to prepend values with (from namespaced groups).
   - Returns: An array of processed Entry items (a catalog).
   */
  init?(path: Path, withPrefix prefix: String) {
    guard path.isDirectory else { return nil }
    let type = path.extension ?? ""
    let metadata = AssetsCatalog.Entry.metadata(path: path)

    switch Constants.Item(rawValue: type) {
    case .colorSet?:
      let name = path.lastComponentWithoutExtension
      self = .color(name: name, value: "\(prefix)\(name)", metadata: metadata)
    case .dataSet?:
      let name = path.lastComponentWithoutExtension
      self = .data(name: name, value: "\(prefix)\(name)", metadata: metadata)
    case .imageSet?:
      let name = path.lastComponentWithoutExtension
      self = .image(name: name, value: "\(prefix)\(name)", metadata: metadata)
    case nil:
      guard type.isEmpty else { return nil }
      let filename = path.lastComponent
      let isNamespaced = AssetsCatalog.Entry.isNamespaced(path: path)
      let subPrefix = isNamespaced ? "\(prefix)\(filename)/" : prefix

      self = .group(
        name: filename,
        isNamespaced: isNamespaced,
        items: AssetsCatalog.Catalog.process(folder: path, withPrefix: subPrefix), 
        metadata: metadata)
      )
    }
  }
}

// MARK: - Private Helpers

extension AssetsCatalog.Entry {
  private static func isNamespaced(path: Path) -> Bool {
    let metadata = self.metadata(for: path)

    if let properties = metadata[Constants.properties] as? [String: Any],
      let providesNamespace = properties[Constants.providesNamespace] as? Bool {
      return providesNamespace
    } else {
      return false
    }
  }

  private static func metadata(for path: Path) -> [String: Any] {
    let contentsFile = path + Path(Constants.path)

    guard let data = try? contentsFile.read(),
      let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
        return [:]
    }

    return (json as? [String: Any]) ?? [:]
  }
}
