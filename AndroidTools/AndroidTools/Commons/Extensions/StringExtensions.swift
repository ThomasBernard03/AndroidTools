//
//  StringExtensions.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

extension String {
    func substringAfterLast(_ delimiter: String) -> String {
        guard let range = self.range(of: delimiter, options: .backwards) else {
            return self
        }

        let indexAfterDelimiter = self.index(range.upperBound, offsetBy: 0)
        return String(self[indexAfterDelimiter...])
    }
    
    func substringBeforeLast(_ delimiter: String) -> String {
        guard let range = self.range(of: delimiter, options: .backwards) else {
            return self
        }

        return String(self[..<range.lowerBound])
    }
    
    func toFileItem(path : String) -> [any FileExplorerItem] {
        let lines = self.split(separator: "\n")
        var items: [any FileExplorerItem] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        

        for line in lines {
            let components = line.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true)

            if components.count >= 8 {
                let permissions = components[0]
                let size = Int(components[4]) ?? 0
                let date = components[5]
                let time = components[6]
                let name = components[7...]
                let filename = name.joined(separator: " ")

                if permissions.first == "d" {
                    items.append(FolderItem(name: filename))
                } else {
                    let lastModificationDate = dateFormatter.date(from:"\(date) \(time)")!
                    items.append(FileItem(name: filename, lastModificationDate: lastModificationDate, size: size))
                }
            }
        }
        
        return items
    }
    
    /**
     Exemples :
     05-13 17:54:38.765 26819 27857 I okhttp.OkHttpClient:         {
     05-13 17:54:38.554 26819 27857 I okhttp.OkHttpClient: --> END GET
     05-13 17:54:37.995  1684  1700 W android.os.Debug: failed to get memory consumption info: -1
     */
    func toLogcatEntry() -> LogEntryModel? {
        let components = self.split(separator: " ", maxSplits: 5)
        
        guard components.count >= 6 else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm:ss.SSS"
        
        guard let date = dateFormatter.date(from: "\(components[0]) \(components[1])") else {
            return nil
        }
        
        guard let processId = Int(components[2]), let threadId = Int(components[3]) else {
            return nil
        }
        
        guard let level = LogLevel(rawValue: String(components[4])) else {
            return nil
        }
        
        let tagAndMessage = components[5].split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        
        guard let tag = tagAndMessage.first?.trimmingCharacters(in: .whitespaces),
              let message = tagAndMessage.last?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        
        return LogEntryModel(datetime: date, processID: processId, threadID: threadId, level: level, tag: tag, message: message)
    }


}
