mobj
===

Some utilities that I keep using.

Of particular note may be the string tokenizer/path walker.

Example
===

Read the code.

No, really.  Give me some examples, dork.
===

Fine.

### Toking Up

This is really the most useful part of the entire library, when you get right down to it.
String is given a method called "tokenize" that allows it's contents to be split up into
a structured path of tokens.  This tokenized path can then be used to do some pretty amazing
things in terms of walking through arbitrarily complex trees of data.  There's a convenience method
on String called "walk" that handles this all for you.

For example, given this object:

```ruby
obj = {
    name: { first: "Joe", last: "Smith" },
    ids: [ 1, 3, 5, 16, 941, 13, 100, 3, 0, 104 ],
    auth_tokens: [ { provider: { name: "example.com", id:123 },
                     token: { auth: "123456", expire: "10-20-2012" } },
                   { provider: { name: "site.com", id:265 },
                     token: { authentication_token: "891011", date: "10-20-2013" } }
    ],
    primary_key: { path: "auth_tokens.provider" }
}
```

Easily traverse it's data using rules embedded into a simple string, like so:

```ruby
# Walk a simple object path:
"name.first".walk(obj)
#=> "Joe"

# Select multiple items out of an object:
"name.first,last".walk(obj)
#=> ["Joe", "Smith"]

# Or indexes (and ranges) in an array:
"ids[1, 3, 5..7, 9+]".walk(obj)
#=> [3, 16, 13, 100, 3, 104]

# Use regular expressions or even method calls as selection keys:
"auth_tokens.token./^auth/.*to_i".walk(obj)
#=> [ 123456, 891011 ]

# Choose the first element that doesn't return nil:
"auth_tokens.token.expire|date".walk(obj)
#=> [ "10-20-2012", "10-20-2013" ]

# Provide default values when everything is nil:
"/auth/.provider,token.auth|authentication_token|~N/A".walk(obj)
#=> ["N/A", "N/A", "123456", "891011"]

# Even look up keys based on the values in other fields:
"{{primary_key.path}}.id".walk(obj)
#=> [123, 265]

```

And much, much more, though you'd probably want to check out the tests to see how it really works.

### Much Ado about Nulling

Every so often you find yourself in a situation where you want nil to behave like "null"
(i.e. you want it to silently allow unknown method calls to simply do nothing instead of throwing
and exception).  All classes are now given a "null!" method that alters the behavior of nil for
the remainder of the line:

```ruby
obj = FooObject.new

if obj.null!.foo.bar.baz
  puts "Acts like normal"
end

obj = nil

if obj.null!.foo.bar.baz
  puts "Won't throw and exception and evaluates to nil"
end

if obj.foo.bar.baz
  puts "Will throw an exception as normal"
end
```

### When you just want to be contrary

Sometimes you just want to write everything in dot notation for no reason.
Or maybe you have a reason, and that reason is impressing your co workers with your
ruby tricks:

```ruby
if foo && foo.bar
  foo.baz
else
  foo.biz
end
```
... becomes ...

```ruby
foo.when.bar.then.baz.else.biz
```

### Sequestration, HashEx, MatchEx, etc

Found myself writing these things sooo many times that I just dumped them into my package of stuff:

```ruby
foo.compact.size == 1 ? foo.compact.first : foo.compact
```
... becomes ...

```ruby
foo.sequester
```

Hash utils:

```ruby
hash = { symbol: "sym", "string" => "string", :nilval => nil }

hash.symbol == hash[:symbol] == hash[:symbol]
#=> These are equvilent

hash.string == hash[:string] == hash["string"]
#=> These are also equvilent

hash.string?
#=> true

hash.nilval?
#=> false

hash.unknown?
#=> True
```

Matching stuff:

```ruby
match = "Joe Bob".match(/(?<first_name>\w+) (?<first_name>)/)

match.to_hash
#=> Creates a hash of named captures

match.first_name if match.first_name?
#=> Or just use them directly as method names

"foo,bar,baz".matches(/([^,]+),/) do |match|
  #=> same as "string#scan", but returns the actual MatchData
end
```

---

Caveats and such
===

All of them.