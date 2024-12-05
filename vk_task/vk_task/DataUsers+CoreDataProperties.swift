//
//  DataUsers+CoreDataProperties.swift
//  vk_task
//
//  Created by bocal on 12/5/24.
//
//

import Foundation
import CoreData


extension DataUsers {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataUsers> {
        return NSFetchRequest<DataUsers>(entityName: "DataUsers")
    }

    @NSManaged public var login: String?
    @NSManaged public var id: Int64
    @NSManaged public var avatar_url: String?
    @NSManaged public var followers_url: String?
    @NSManaged public var following_url: String?

}

extension DataUsers : Identifiable {

}
