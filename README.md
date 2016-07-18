# inject

I wanted to learn Swift so i decided to try something easy as a start; a dependency Injection Container for Swift :-)

`Inject` is a dependency injection container for Swift that picks up the basic Spring ideas.

Let's look at an example first

Here is a sample `application.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans
    xmlns="http://www.springframework.org/schema/beans"
    xsi:schemaLocation="
    http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.2.xsd
    http://www.springframework.org/schema/configuration http://www.springframework.org/schema/util/spring-util.xsd">

    <bean id="data" class="Data">
        <property name="string" value="data"/>
        <property name="int" value="1"/>
        <property name="float" value="-1.1"/>
        <property name="double" value="-2.2"/>
    </bean>
```

As you can see, i was too lazy to create an own xsd, so i stuck to the spring xsd :-)

Fetching Beans is done like this:

```swift
var data = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("application", withExtension: "xml")!)!
    
var context = try! ApplicationContext(
   parent: nil,
   data: data
)
        
let bean = try! context.getBean(byId: "data") as! Data
// other possibility is
let sameBean = try! context.getBean(byType: Data.self) as! Data

```

Here is a brief summary of the supported features
* full dependency management including `depends-on`, `ref`, embedded `<bean>`'s as property values, and injections
* property injections ( only.. ) including automatic type conversions
* injections resembling the spring `@Inject` autowiring mechanism
* support for different scopes including `singleton`  and `protoype` as builtin flavors
* support for lazy initialized beans
* support for bean templates ( e.g. `parent="<id>"` )
* lifecycle methods ( e.g. `postConstruct` )
* `BeanPostProcessor`'s
* support for hierarchical containers, inheriting all aspects
* support for placeholder resolution in xml files ( e.g. `${property=<default>}`) referencing possible configuration values that are retrieved by different providers ( e.g. process info, plists, etc. )
* support for custom namespace handlers that are much more easy to handle than in the spring world

What is still missing ( mainly due to the crappy Swift support for reflection )
* method injection
* constructor injection
* `FactoryBean`'s
* let me think...hmmm

And there are also limitations ( darn )
* all objects need to derive from `NSObject` and include a `@objc` annotation
* all objects need to have a dafault `init` function
* all properties that are injected cannot be optional! ( Woooo.. )

Roadmap
* support the different package managers
