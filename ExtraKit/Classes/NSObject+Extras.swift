import Foundation
import ObjectiveC

private var associatedDictionaryKey = 0

public extension NSObject {

	var associatedDictionary: NSMutableDictionary {
		get {
			if let dict = objc_getAssociatedObject(self, &associatedDictionaryKey) as? NSMutableDictionary {
				return dict
			}
			let dict = NSMutableDictionary()
			objc_setAssociatedObject(self, &associatedDictionaryKey, dict, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return dict
		}
	}
	
	func associatedValueForKey<T>(_ key: String) -> T? {
		return associatedDictionary[key] as? T
	}
	
	func setAssociatedValue(_ value: Any?, forKey key: String) {
		associatedDictionary[key] = value
	}

	func weakAssociatedValueForKey<T>(_ key: String) -> T? {
		return (associatedDictionary[key] as? WeakObjectRef)?.object as? T
	}
	
	func setWeakAssociatedValue(_ value: AnyObject?, forKey key: String) {
		associatedDictionary[key] = WeakObjectRef(value)
	}

}

private let associatedValueKey = "com.rickb.extrakit.Observing"

public extension NSObject
{
	func startObserving(_ name: NSNotification.Name, object: AnyHashable? = nil, queue: OperationQueue? = nil, usingBlock block: @escaping (Notification) -> Void) {
		setAssociatedValue(NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: block)
		, forKey: "\(associatedValueKey).\(name).\(object?.hashValue ?? 0)")
	}
	
	func stopObserving(_ name: NSNotification.Name, object: AnyHashable? = nil) {
		setAssociatedValue(nil, forKey: "\(associatedValueKey).\(name).\(object?.hashValue ?? 0)")
	}
}

public extension NSObject {

	class func swizzle(_ originalSelector: Selector, newSelector: Selector) {
		
		let originalMethod = class_getInstanceMethod(self, originalSelector)
		let newMethod = class_getInstanceMethod(self, newSelector)
		
		let methodAdded = class_addMethod(self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))
		if methodAdded {
			class_replaceMethod(self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
		} else {
			method_exchangeImplementations(originalMethod, newMethod)
		}
	}
}


open class WeakObjectRef: NSObject {
	weak var object: AnyObject?
	
	init(_ object: AnyObject?) {
		self.object = object
	}
}
