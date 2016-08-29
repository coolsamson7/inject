# inject

[![Swift Version](https://img.shields.io/badge/Swift-2.2-F16D39.svg?style=flat)](https://developer.apple.com/swift)
[![Build Status](https://travis-ci.org/coolsamson7/inject.svg?style=flat)](https://travis-ci.org/coolsamson7/inject)
[![CocoaPods](https://img.shields.io/cocoapods/v/inject.svg)](https://github.com/coolsamson7/inject)
[![Platform](https://img.shields.io/cocoapods/p/inject.svg?style=flat)](http://cocoapods.org/pods/inject)
[![License][mit-badge]][mit-url]

<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/19403960/17474460/43a71bd6-5d56-11e6-9bcb-6d2aaa9ac466.png" width="40%">
</p>

`Inject` is a dependency injection container for Swift that picks up the basic `Spring` ideas - as far as they are possible to be implemented - and additionally utilizes the Swift language features - e.g. closures - in order to provide a simple and intuitive api.

In addition to the core a number of other concepts are implemented
* basic reflection and type introspection features 
* configuration framework
* logging &  tracing framework
* concurrency classes
* xml parser
* type conversion facilities

But let's come back to the dependency container again :-)

# What's a dependency injection container anyway?

The basic idea is to have one central object that knows about all kind of different object types and object dependencies and whose task is to instantiate and assemble them appropriately by populating fields ( with property setters, methods or appropriate constructor calls ). Classes do not have to know anything about the current infrastructure - e.g. specific  protocol implementation, or specific configuration values - as this know how is solely in the responsiblity of the container and injected into the classes.

If you think about unit testing, where service implementations need to be exchanged by some kind of local variants ( e.g. mocks ) you get a feeling for the benefits.

The other big benefit is that the lifecycle of objects is also managed by a central instance. This on the one hand avoids singleton patterns all over your code - which simply is a mess - and on the other hand allows for other features such as session scoped objects, or the possibility to shutdown the complete container - releasing ressources - with on call.

# Features

Here is a summary of the supported features
* specification of beans via a fluent interface or xml
* full dependency management including cycle detection 
* all defintions are checked for typesafeness
* integrated management of configuration values
* injections resembling the spring `@Inject` autowiring mechanism
* support for different scopes including `singleton`  and `protoype` as builtin flavors
* support for lazy initialized beans
* support for bean templates
* lifecycle methods ( e.g. `postConstruct` )
* `BeanPostProcessor`'s
* `FactoryBean`'s
* support for hierarchical containers, that inherit beans ( and post processors )
* support for placeholder resolution ( e.g. `${property=<default>}`) in xml 
* support for custom namespace handlers in xml
* automatic type conversions and number coercions in xml

# Documentation

For detailed information please visit

* The [Wiki](https://github.com/coolsamson7/inject/wiki) and
* the generated [API Docs](http://cocoadocs.org/docsets/inject/1.0.2/)
* or simply play around with the included playground

# Examples

Let's look at some simple examples.

```Swift
let environment = try! Environment(name: "my first environment")

try! environment
   // a bar created by the default constructor
   
   .define(environment.bean(Bar.self, factory: Bar.init))
   
   // a foo that depends on bar
   
   .define(environment.bean(Foo.self, factory: {
            return Foo(bar: try! environment.getBean(Bar.self))
        }).requires(class: Bar.self))
        
   // get goin'
   
   .startup()
```

One the environment is configured, beans can simply be retrieved via the `getBean()` function.

```Swift
let foo = try environment.getBean(Foo.self)
```
Behind the scenes all bean definitions will be validated - e.g. looking for cyclic dependencies or non resolvable dependencies - and all singleton beans will be eagerly constructed.

Other injections - here property injections - can be expressed via the fluent interface

```Swift
environment.define(environment.bean(Foo.self, id: "foo-1")
   .property("name", value: "foo")
   .property("number", value: 7))
```

**Injections**

A similar concept as the Java `@Inject` annotations is available that let's you define injections on a class basis.

```Swift
public class AbstractConfigurationSource : NSObject, Bean, BeanDescriptorInitializer, ... {
    // MARK: instance data
    
    ...
    var configurationManager : ConfigurationManager? = nil // injected
    
    ...
    
    // MARK: implement BeanDescriptorInitializer
    
    public func initializeBeanDescriptor(beanDescriptor : BeanDescriptor) {
        beanDescriptor["configurationManager"].inject(InjectBean())
    }
    
    // MARK: implement Bean
    
    // we know, that all injections have been executed....
    public func postConstruct() throws -> Void {
        try configurationManager!.addSource(self)
    }
```

The protocol `BeanDescriptorInitializer` can be implemented for thus purpose in order to add inejctions to properties. Valid values are:
* `InjectBean` an injection for a specific object type
* `InjectConfigurationValue` an injection of a configuration value

**Scopes**

Scopes determine when and how often a bean instance is created. 
* The default is "singleton", which will create an instance once and will cache the value.
* "prototype" will recreate a  new instance whenever a bean is requested.

**Example**: 
```Swift
environment.define(environment.bean(Foo.self)
   .scope("prototype")
   .property("name", value: "foo")
   .property("number", value: 7))
```

Other scopes can be simply added (e.g. session scope ) by defining the implementing class in the current environment.

**Lazy Beans**

Beans that are marked as lazy will be constructed after the first request.

**Factory Beans**

Factory beans are beans that implement a specific protocol and create other beans in turn.

```Swift
environment
   .define(environment.bean(FooFactory.self)
      .property("someProperty", value: "...") // configure the factory....
      .target(Foo.self) // i will create foo's
    )
    
let foo = environment.getBean(Foo.self) // is created by the factory!
```

**Abstract Beans**

It is possible to define a bean skeletton - possibly hiding ugly technical parameters - and let the programmer finsh configuration by adding the missing parts:

```Swift
environment
   // a template

   .define(environment.bean(Foo.self, id: "foo-template", abstract: true)
      .property("url", value: "...")
      .property("port", value: 8080))
   
   // the concrete bean
   
   .define(environment.bean(Foo.self, parent: "foo-template")
      .property("missing", value: "foo") // add missing properties
   )
```
Usually templates are part of a parent environment to separate technical aspects.

**Bean Post Processor**

Bean Post Processors are classes that implement a specific protocol and are called by the container in order to modify the to be constructed instance.

**Lifecycle Callbacks**

Different protocols can be implemenetd by classes which will be called by the container when an instance is created.
The most important is a `postConstruct` that is called after the instance has been created and all psot processors have been executed. 

**Configuration Values**

Every container defines a central registry that maintains configuration values - from different sources - that can be retrieved with an uniform api.

```Swift
let environment = ...
environment.addConfigurationSource(ProcessInfoConfigurationSource()) // process info
environment.addConfigurationSource(PlistConfigurationSource(name: "Info")) // will read Info.plist in the current bundle

// retrieve some values

environment.getConfigurationValue(Int.self, key: "SIMULATOR_MAINSCREEN_HEIGHT", defaultValue: 100) // implicit conversion!
```

**XML Configuration**

And for all xml lovers ( :-) ), an xml parser for the original - at least a subset - spring schema.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans
        xmlns:configuration="http://www.springframework.org/schema/configuration"
        xmlns="http://www.springframework.org/schema/beans"
        xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.2.xsd
                        http://www.springframework.org/schema/configuration http://www.springframework.org/schema/util/spring-util.xsd">
    
    <!-- configuration values are collected from different sources and can be referenced in xml and the api -->
    <!-- in addition to static values dynamic sources are supported that will trigger listeners or simply change injected values on the fly-->
    
    <!-- here are some examples for sources -->
    
    <!-- builtin namespace & corresponding handler to set configuration values -->

    <configuration:configuration namespace="com.foo">
        <configuration:define key="bar" type="Int" value="1"/>
    </configuration:configuration>
    
    <!-- other supported sources are -->
    
    <!-- the current process info values, e.g. "PATH" -->
    
    <bean class="Inject.ProcessInfoConfigurationSource"/>
    
    <!-- a plist -->

    <bean class="Inject.PlistConfigurationSource">
        <property name="name" value="Info"/>
    </bean>
    
    <!-- a post processor will be called by the container after construction giving it the chance -->
    <!-- to modify it or completely exchange it with another object ( proxy... ) -->
    
    <!-- here we simple print every bean on stdout...:-) -->

    <bean class="SamplePostProcessor"/>

    <!-- create some foo's -->

    <!-- depends-on will switch the instantiation order -->

    <bean id="foo-1" class="Foo" depends-on="foo-2">
        <property name="id" value="foo-1"/>
        <!-- references an unknown configuration key, which will set the default value instead... -->
        <property name="number" value="${dunno=1}"/>
    </bean>

    <bean id="foo-2" class="Foo">
        <property name="id" value="foo-2"/>
        <!-- same thing recursively -->
        <property name="number" value="${dunno=${wtf=1}}"/>
    </bean>

    <!-- scope prototype means that whenever the bean is requestd a new instance will be created ( default scope is singleton ) -->
    <!-- other scopes yould be easily added, e.g. a session scope... -->

    <bean id="foo-prototype" class="Foo" scope="prototype">
        <property name="id" value="foo-prototype"/>
        <!-- this should work... the : separates the namespace from the key! -->
        <property name="number" value="${com.foo:bar}"/>
    </bean>

    <!-- bar will be injected by all foo's. Obviously the bar needs to be constructed first -->

    <bean id="bar-parent" class="Bar" abstract="true">
        <property name="magic" value="4711"/>
    </bean>

    <!-- will inherit the magic number -->
    <!-- lazy means that it will be constructed when requested for the first time -->

    <bean id="bar" class="Bar" parent="bar-parent" lazy="true">
        <property name="id" value="bar"/>
    </bean>

    <!-- both foo's will inject the bar instance -->

    <!-- baz factory will create Baz instances... -->

    <bean class="BazFactory" target="Baz">
        <property name="name" value="factory"/>
        <!-- will be set as the baz id... -->
        <property name="id" value="id"/>
    </bean>

    <!-- bazongs -->

    <bean id="bazong-1" class="Bazong">
        <property name="id" value="id"/>
        <!-- by reference -->
        <property name="foo" ref="foo-1"/>
    </bean>

    <bean id="bazong-2" class="Bazong">
        <property name="id" value="id"/>
        <!-- in-place -->
        <property name="foo">
            <bean class="Foo">
                <property name="id" value="foo-3"/>
                <property name="number" value="1"/>
            </bean>
        </property>
    </bean>
</beans>
```

```Swift
var environment = Environment(name: "environment")
var data : NSData = ...
environment
   .loadXML(data)
   .startup()  
```

# Logging

In addition to the injection container, a logging framework has been implemented - and integrated - as well.  

Once the singleton is configured

```swift
// a composition of the different possible log entry constituents

let formatter = LogFormatter.timestamp("dd/M/yyyy, H:mm:s") + " [" + LogFormatter.logger() + "] " + LogFormatter.level() + " - " + LogFormatter.message()
let consoleLogger = ConsoleLog(name: "console", formatter: formatter, synchronize: false)

LogManager() 
           .registerLogger("", level : .OFF, logs: [QueuedLog(name: "console", delegate: consoleLogger)]) // root logger
           .registerLogger("Inject", level : .WARN) // will inherit all log destinations
           .registerLogger("Inject.Environment", level : .ALL)
```

the usual methods are provided

```swift
// this is usually a static var in a class!
var logger = LogManager.getLogger(forClass: MyClass.self) // will lookup with the fully qualified name

logger.warn("ouch!") // this is a autoclosure!

logger.fatal(SomeError(), message: "ouch")
```
The `error` and `fatal` functions are called with an `ErrorType` argument. Both functions will emit an message containing the original message, the error representation and the current stacktrace.

Provided log destinations are
* console
* file
* rolling file log (logs get copied every day) 
* nslog
* queued log destination

The queueded log destination uses a dispatch queue. As a default a serial queue will be created whose purpose simply is to serialize the entries. In this case ´synchronize: false´ prevents that the console operations are synchronized with a Mutex

## Requirements

- iOS 8.0+
- OSX 10.9
- WatchOS 2.0
- TvOS 9.0
- Xcode 7.0+

# Installation

## Cocoapods

To install with CocoaPods, add `pod 'inject', '~> 1.0.2'`  to your `Podfile`, e.g.

```ruby
target 'MyApp' do
  pod 'inject', '~> 1.0.2'
end
```

Then run `pod install` command. For details of the installation and usage of CocoaPods, visit [its official website](https://cocoapods.org).

# Limitations

Depending on the specific bean definition, it may be required that the corresponding classes derive from `NSObject`.
This limitation is due to the - missing - `Swift` support for relection. As soon as the language evolves i would change that. 

# Roadmap
* support more package managers
* wait for replies :-)

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
