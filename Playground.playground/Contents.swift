//: Playground - noun: a place where people can play


import Foundation

import Inject

// logger

var formatter = LogFormatter.timestamp("dd/M/yyyy, H:mm:s") + " [" + LogFormatter.logger() + "] " + LogFormatter.level()

let consoleLog = ConsoleLog(name: "console", formatter: formatter)

LogManager.getSingleton()
    .registerLogger("", level : .off, logs: [QueuedLog(name: "console", delegate: consoleLog)]) // root logger
    .registerLogger("Inject", level : .warn) // will inherit all log destinations
    .registerLogger("Inject.Environment", level : .all)


// this is usually a static var in a class!

var logger = LogManager.getLogger(forName: "Inject")

logger.info("will not be emitted")
logger.warn("ouch!") // this is a autoclosure!

// environment

// a post processor

class SamplePostProcessor : BeanPostProcessor {
    // implement BeanPostProcessor
    
    func process(_ bean : AnyObject) throws -> AnyObject {
        print("post process \(bean)...")
        
        return bean
    }
}

// the famous foo

class Foo : NSObject, Bean, BeanDescriptorInitializer { // the injection requires a NSObject
    // instance data
    
    var id : String = ""
    var number : Int = 0
    var bar : Bar?
    
    // init
    
    override init() {
        super.init()
    }
    
    // implement Bean
    
    func postConstruct() throws -> Void {
        print("postConstruct(\(self))")
    }
    
    // implement BeanDescriptorInitializer
    
    func initializeBeanDescriptor(_ beanDescriptor : BeanDescriptor) {
        beanDescriptor["bar"].inject(InjectBean())
    }
    
    // CustomStringConvertible
    
    override internal var description: String {
        return "foo[id: \(id), number: \(number), bar: \(String(describing: bar))]"
    }
}

// a bar

class Bar : NSObject, EnvironmentAware {
    // instance data
    
    var id : String = ""
    var magic = 0
    
    // init
    
    override init() {
        super.init()
    }
    
    // implement EnvironmentAware
    
    var _environment : Environment?
    
    var environment: Environment? {
        get {
            return _environment
        }
        set {
            _environment = newValue
        }
    }
    
    // CustomStringConvertible
    
    override internal var description: String {
        return "bar[id: \(id), magic: \(magic)]"
    }
}

// a factory

// this is the only class that needs to derive from NSObject since we do property injection
class BazFactory : NSObject, FactoryBean {
    // instance data
    
    var name : String = ""
    var id : String = ""
    
    // init
    
    override init() {
        super.init()
    }
    
    // implement FactoryBean
    
    func create() throws -> AnyObject {
        let result = Baz()
        
        result.factory = name
        result.id = id
        
        return result
    }
    
    // CustomStringConvertible
    
    override internal var description: String {
        return "baz-factory[name: \(name), id: \(id)]"
    }
}

// baz

class Baz : Initializable {
    // instance data
    
    var factory : String = "" // that's my factory
    var id : String = ""
    
    // init
    
    required init() {
    }
    
    // CustomStringConvertible
    
    internal var description: String {
        return "baz[id: \(id), factory: \(factory)]"
    }
}

// setup tracing

Tracer.setTraceLevel("inject", level : .full)

// create the environment

let environment = try Environment(name: "environment", traceOrigin: true) // track the origin for debug purposes

try environment
    // add process info 
    
    .addConfigurationSource(ProcessInfoConfigurationSource())
    
    // some manual settings
    
    .define(environment.settings()
        .setValue("foo", key: "number", value: "1")
        .setValue("foo", key: "id", value: "id!")
    )
    
    // a post processor
    
    .define(environment.bean(SamplePostProcessor()))
    
    // foo
    
    .define(environment.bean(Foo.self, factory: {
        let foo = Foo()
    
        foo.id     = try environment.getConfigurationValue(String.self, namespace: "foo", key: "id")
        foo.number = try environment.getConfigurationValue(Int.self, namespace: "foo", key: "number", defaultValue: -1)
        
        //foo.bar = try environment.getBean(Bar.self)
        
        return foo
    })
        .requires(class: Bar.self))
    
    // bar
    
    .define(environment.bean(Bar.self, factory: Bar.init))

    // the factory

    .define(environment.bean(BazFactory.self)
        .target(Baz.self)
        .property("name", value: "baz factory")
        .property("id", value: "generated id"))

    // go forrest
    
     .startup()

// create report

print(environment.report())

// create a report of the configuration values

print(environment.getConfigurationManager().report())

// fetch a foo

let foo = try environment.getBean(Foo.self)

print("foo: \(foo)")

// fetch a bar

let bar = try environment.getBean(Bar.self)

print("bar: \(bar)")

// let the factory create a baz

let baz = try environment.getBean(Baz.self)

print("baz created by factory: \(baz)")

// list all foos...

let foos = try environment.getBeansByType(Foo.self)

print("foos: \(foos)")

// check error logging :-)

do {
    try environment.getBean(String.self)
}
catch {
    logger.error(error, message: "")
}




