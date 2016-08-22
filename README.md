# inject

[![Swift Version](https://img.shields.io/badge/Swift-2.2-F16D39.svg?style=flat)](https://developer.apple.com/swift)
[![Build Status](https://travis-ci.org/coolsamson7/inject.svg?style=flat)](https://travis-ci.org/coolsamson7/inject)
[![CocoaPods](https://img.shields.io/cocoapods/v/inject.svg)](https://github.com/coolsamson7/inject)
[![License][mit-badge]][mit-url]

<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/19403960/17474460/43a71bd6-5d56-11e6-9bcb-6d2aaa9ac466.png" width="40%">
</p>

`Inject` is a dependency injection container for Swift that picks up the basic `Spring` ideas - as far as they are possible to be implemented due to missing reflection features - but in addition offers several configuration possibilities:
* configuration with xml files
* fluent interface depending on reflection features
* fluent interface applying closure functions ( without the need for reflection anymore )

In addition a number of other concepts are implemented
* basic reflection and type introspection features 
* configuration framework
* logging framework
* tracing framework
* threading classes
* xml parser
* type conversion facilities

But let's come back to the dependency container again :-)

# Features

Here is a summary of the supported features
* full dependency management - and cycle detection - including `depends-on`, `ref`, embedded `<bean>`'s as property values, and injections
* full typechecking with respect to property values
* property injections ( only.. ) including automatic type conversions and number coercions ( for the fluent part )
* injections resembling the spring `@Inject` autowiring mechanism
* support for different scopes including `singleton`  and `protoype` as builtin flavors
* support for lazy initialized beans
* support for bean templates ( e.g. `parent="<id>"` )
* lifecycle methods ( e.g. `postConstruct` )
* `BeanPostProcessor`'s
* `FactoryBean`'s
* support for hierarchical containers, inheriting beans ( including the post processors, of course )
* support for placeholder resolution ( e.g. `${property=<default>}`) referencing possible configuration values that are retrieved by different providers ( e.g. process info, plists, etc. )
* support for custom namespace handlers that are much more easy to handle than in the spring world


Let's look at an xml example first ( included in the repository )

Here is a sample configuration file `sample.xml` that will demonstrate most of the features
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

As you can see, i was too lazy to create an own xsd, so i will stick to the spring xsd for now :-)

Once the container is setup, which is done like this:

```swift
var data : NSData = NSData(contentsOfURL: NSBundle(forClass: SampleTest.self).URLForResource("sample", withExtension: "xml")!)!
    
var environment = Environment(name: "environment")

environment
   .loadXML(data)
   .startup() // would be done on demand anyway whenever a getter is called that references the internal layout 
```
beans can be retrieved via a simple api

```swift
// by type if one instance only exists ( it would throw an error otherwise )

let baz = try environment.getBean(Baz.self)

// by id

let foo = try environment.getBean(Foo.self, byId: "foo-1")

```

If you don't like xml a fluent interface is provided that will offer the same features.

Here is the - more or less - equivalent

```swift
let environment = try Environment(name: "fluent environment")

try environment.addConfigurationSource(ProcessInfoConfigurationSource())
try environment.addConfigurationSource(PlistConfigurationSource(name: "Info"))

try environment
    .define(environment.bean(SamplePostProcessor.self))

    .define(environment.bean(Foo(), id: "constructed foo")) // plain object

    .define(environment.bean(Foo.self, id: "foo-by-factory", factory: {return Foo()})) // closure factory
     
    .define(environment.bean(Foo.self, id: "foo-1")
        .property("id", value: "foo-1")
        //.property("bar", inject: InjectBean()) the injection is expressed in the class itself, so this is not needed!
        .property("number", resolve: "${dunno=1}"))

    .define(environment.bean(Foo.self, id: "foo-prototype")
        .scope(environment.scope("prototype"))
        .property("id", value: "foo-prototype")
        //.property("bar", inject: InjectBean()) the injection is expressed in the class itself, so this is not needed!
        .property("number", resolve: "${com.foo:bar=1}"))

    .define(environment.bean(Bar.self, id: "bar-parent", abstract: true)
        .property("magic", value: 4711))

    .define(environment.bean(Bar.self, id: "bar", lazy: true)
        .parent("bar-parent")
        .property("id", value: "bar"))

    .define(environment.bean(BazFactory.self, id: "baz")
        .property("name", value: "factory")
        .property("id", value: "id"))

    .define(environment.bean(Bazong.self, id: "bazong-1")
        .property("id", value: "id")
        .property("foo", ref: "foo-1"))

    .define(environment.bean(Bazong.self, id: "bazong-2")
        .property("id", value: "id")
        .property("foo", bean: environment.bean(Foo.self)
            .property("id", value: "foo-3")
            .property("number", value: 1)))

    .startup()
```
Both mechanisms heavily rely in reflection which is used to create instances and set properties. The drawback is that - at least in the current version - the corresponding objects need to derive from `NSObject` in order to use the corresponding low level methods. It is possible to avoid that, if 
* property setters are avoided, and
* "constructors" are realized by closure functions

Let's look at another example ( assuming two plain swift classes `Swift` and `AnotherSwift` ):

```swift
let environment = try Environment(name: "closure environment")

try environment
     .define(environment.bean(Swift.self, factory: {
            let swift = Swift(name:  try environment.getValue(String.self, key: "dunno", defaultValue: "default")) // access configuration values

            // set additional properties
            
            swift.other = try environment.getBean(AnotherSwift.self) // must be constructed first!

            return swift
        }).requires(class: AnotherSwift.self))

        .define(environment.bean(AnotherSwift.self, factory: {
            AnotherSwift(name: "other swift")
        }))
```
As you see, the provided closure functions both create the object and set properties. In order to guarantee that all dependencies are available, dependencies explicitely nned to be declared by the `requires` function!

Even in this case there is a small prerequisite for the used classes since an internal type registry that collects structural infromation on all object needs to crate a prototype object in order to analzye the properties: The classes need to implement a protocol `Initializable` that simply declares a function `init()`.

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
var logger = LogManager.getLogger(forClass: MyClass.self) // will build the fully qualified name

logger.warn("ouch!") // this is a autoclosure!
```
Provided log destinations are
* console
* file
* queued log destination

The queueded log destination uses a dispatch queue. As a default a serial queue will be created whose purpose simply is to serialize the entries. In this case ´synchronize: false´ prevents that the console operations are synchronized with a Mutex

## Requirements

- iOS 8.0+
- Xcode 7.0+

# Documentation

* Check the [Wiki](https://github.com/coolsamson7/inject/wiki)
* API Docs [here](http://cocoadocs.org/docsets/inject/1.0.1/)

# Installation

## Cocoapods

To install with CocoaPods, add `pod 'inject', '~> 1.0.0'`  to your `Podfile`, e.g.

```ruby
target 'MyApp' do
  pod 'inject', '~> 1.0.0'
end
```

Then run `pod install` command. For details of the installation and usage of CocoaPods, visit [its official website](https://cocoapods.org).

# Missing

What is still missing ( mainly due to the crappy Swift support for reflection )
* method injection
* constructor injection
* let me think...hmmm

# Limitations

And there are also limitations ( darn )
* all reflection usage requires the corresponding objects need to derive from `NSObject` ( xml and fluent interface with property setters )

This limitation is due to the - missing - swift support for relection. As soon as the language evolves i would change that.. 
# Roadmap
* support more package managers
* wait for replies :-)
* internal type system on top of the swift low level types ( answering questions like: what are the implemented protocols of a class, is a class a number type, is one type assignable from another type, what are my generic parameters, etc. ) 
* support more injections
* integrate proxy patterns as a basis for a service framework

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
