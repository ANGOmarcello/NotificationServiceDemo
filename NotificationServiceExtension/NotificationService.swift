//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Angelo Cammalleri on 18.05.17.
//  Copyright © 2017 Angelo Cammalleri. All rights reserved.
//

import UserNotifications
import UIKit

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = "This is a modified notification." +
                                       "\(bestAttemptContent.title)"
            
            // Modify the notification content here...
            if let url = parsePictureURL(request) {
                downloadAndAttachPicture(url: url)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content,
        // otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Handling Methods
    
    /**
     Parses the recieved notification for its pictureURL.
     - parameter request: The request object you recieved with your notification.
     - returns: Url if parsing was succesfull and nil if not.
     */
    func parsePictureURL(_ request: UNNotificationRequest) -> URL? {
        guard let result = request.content.userInfo["aps"] as? [String:Any] else {
            return nil
        }
        
        guard let urlString = result["pictureURL"] as? String,
            let url = URL(string: urlString) else {
            return nil
        }
        
        return url
    }
    
    /**
     Downloads the picture from the specified url.
     - parameter url: The url to the image you want to download.
     */
    func downloadAndAttachPicture(url: URL) {
        let session = URLSession(configuration: .default)
        let downloadPicTask = session.dataTask(with: url) { (data, response, error) in
            guard let res = response as? HTTPURLResponse else {
                print("Couldn't get response.")
                return
            }
            
            if let e = error {
                print("Error downloading picture: \(e)")
                return
            }
            
            print("Downloaded picture with response code \(res.statusCode)")
            
            guard let imageData = data else {
                print("Couldn't get image: Image is nil")
                return
            }
            
            let image = UIImage(data: imageData)
            
            guard let attachmentImage = UNNotificationAttachment.create(identifier:UUID().uuidString,
                                                                        image: image!,
                                                                        options: nil)
            else {
                print("Failed to create UNNotificationAttachment.")
                return
            }
            
            if let bestAttemptContent = self.bestAttemptContent, let contentHandler = self.contentHandler {
                bestAttemptContent.attachments.append(attachmentImage)
                contentHandler(bestAttemptContent)
            }
        }
        
        downloadPicTask.resume()
    }
}

extension UNNotificationAttachment {
    
    /**
     Helps with the creation of an UNNotificationAttachment from an image.
     - parameter identifier: The unique identifier of the attachment. Use this string to identify the attachment later. If you don't specify an identifier, this method creates a unique one for you.
     - parameter image: The image you want to create an attachemnt from.
     - parameter options: A dictionary of options related to the attached file. Use the options to specify meta information about the attachment, such as the clipping rectangle to use for the resulting thumbnail. For a list of keys that you can include in this dictionary, see Attachment Attributes.
     - returns: The initialised UNNotificationAttachment.
     */
    static func create(identifier: String?,
                       image: UIImage,
                       options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName,
                                                                                                  isDirectory: true)
        do {
            // Creating a temp folder for the image
            try fileManager.createDirectory(at: tmpSubFolderURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            
             // Creating an identifier if you did not supply one
            var imageFileIdentifier: String?
           
            if let identifier = identifier {
                imageFileIdentifier = identifier + ".png"
            } else {
                imageFileIdentifier = UUID().uuidString + ".png"
            }
            
            // Saving the image file to the temp folder
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier!)
            
            guard let imageData = UIImagePNGRepresentation(image) else {
                return nil
            }
            
            try imageData.write(to: fileURL)
            
            // Creating the actual attachment
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier!,
                                                                    url: fileURL,
                                                                    options: options)
            
            return imageAttachment
        } catch {
            print("error " + error.localizedDescription)
        }
        
        return nil
    }
}
