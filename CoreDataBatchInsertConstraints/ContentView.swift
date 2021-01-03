//
//  ContentView.swift
//  CoreDataBatchInsertConstraints
//
//  Created by Toomas Vahter on 03.01.2021.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.products) { item in
                    Text(item.name!)
                }
                .onDelete(perform: deleteProducts)
            }
            .navigationBarTitle("Products")
            .navigationBarItems(trailing: makeAddItem())
        }
    }
    
    private func makeAddItem() -> some View {
        HStack {
            Button(action: addProduct) {
                Text("Add")
            }
            Button(action: importProducts) {
                Text("Import")
            }
        }
    }

    private func addProduct() {
        withAnimation {
            viewModel.addProduct()
        }
    }

    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            viewModel.deleteProducts(offsets: offsets)
        }
    }
    
    private func importProducts() {
        viewModel.importProducts {
            withAnimation {
                viewModel.refetchProducts()
            }
        }
    }
}

extension ContentView {
    final class ViewModel: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
        private let persistenceController: PersistenceController
        private let resultsController: NSFetchedResultsController<Product>
        
        init(persistenceController: PersistenceController = .shared) {
            self.persistenceController = persistenceController
            resultsController = {
                let request = NSFetchRequest<Product>(entityName: "Product")
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.name, ascending: true)]
                return NSFetchedResultsController(fetchRequest: request, managedObjectContext: persistenceController.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            }()
            super.init()
            resultsController.delegate = self
            refetchProducts()
        }
        
        var products: [Product] {
            return resultsController.fetchedObjects ?? []
        }
        
        func refetchProducts() {
            objectWillChange.send()
            try? resultsController.performFetch()
        }
        
        func importProducts(completionHandler: @escaping () -> Void) {
            // Simulates fetching products from network and importing all the items to the persistent store
            ProductAPI.getAll { result in
                switch result {
                case .success(let products):
                    self.persistenceController.container.performBackgroundTask { context in
                        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                        let batchInsert = NSBatchInsertRequest(entityName: "Product", objects: products)
                        do {
                            let result = try context.execute(batchInsert) as! NSBatchInsertResult
                            print(result)
                        }
                        catch {
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        DispatchQueue.main.async {
                            completionHandler()
                        }
                    }
                case .failure(_):
                    // TODO: failure handling
                    break
                }
            }
        }
        
        func addProduct() {
            let newItem = Product(context: persistenceController.container.viewContext)
            newItem.name = "Coffee"
            newItem.serialCode = UUID().uuidString

            do {
                try persistenceController.container.viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
        
        func deleteProducts(offsets: IndexSet) {
            offsets.map { products[$0] }.forEach(persistenceController.container.viewContext.delete)

            do {
                try persistenceController.container.viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
        
        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            objectWillChange.send()
        }
    }
}

struct ProductAPI {
    static func getAll(withCompletionHandler completionHandler: @escaping (Result<[[String: Any]], Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let products: [[String: Any]] = [
                ["name": "Cafe Latte", "serialCode": "coffee-1"],
                ["name": "Cappuchino", "serialCode": "coffee-2"],
                ["name": "Flat White", "serialCode": "coffee-3"]
            ]
            completionHandler(.success(products))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
