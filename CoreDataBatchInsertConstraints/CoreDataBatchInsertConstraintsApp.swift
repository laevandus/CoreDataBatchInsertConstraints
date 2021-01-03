//
//  CoreDataBatchInsertConstraintsApp.swift
//  CoreDataBatchInsertConstraints
//
//  Created by Toomas Vahter on 03.01.2021.
//

import SwiftUI

@main
struct CoreDataBatchInsertConstraintsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
