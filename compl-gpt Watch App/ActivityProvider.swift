import Foundation
import HealthKit

class ActivityProvider: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    private let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    override init() {
        super.init()
        
        healthStore.requestAuthorization(toShare: [], read: [stepsType, caloriesType]) { (success, error) in
            if success {
                print("Authorization successful.")
            } else {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func getActivity() async throws -> Activity {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let steps = try await getSteps(predicate: predicate)
        let calories = try await getCalories(predicate: predicate)
        
        return Activity(steps: steps, calories: calories)
    }
    
    
    private func getCalories(predicate: NSPredicate) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    if let hkError = error as? HKError {
                        if hkError.code == HKError.Code.errorNoData {
                            continuation.resume(returning: 0)
                            return
                        }
                    }
                    continuation.resume(throwing: error)
                } else if let result = result,
                          let sum = result.sumQuantity() {
                    let calories = Int(sum.doubleValue(for: HKUnit.largeCalorie()))
                    continuation.resume(returning: calories)
                } else {
                    continuation.resume(throwing: NSError(domain: "getCalories", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch calories"]))
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func getSteps(predicate: NSPredicate) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    if let hkError = error as? HKError {
                        if hkError.code == HKError.Code.errorNoData {
                            continuation.resume(returning: 0)
                            return
                        }
                    }
                    continuation.resume(throwing: error)
                } else if let result = result,
                          let sum = result.sumQuantity() {
                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: stepCount)
                } else {
                    continuation.resume(throwing: NSError(domain: "getSteps", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch step count"]))
                }
            }
            
            healthStore.execute(query)
        }
    }
}

struct Activity {
    static let Sample = Activity(steps: -1, calories: -1)
    
    let steps: Int
    let calories: Int
}
