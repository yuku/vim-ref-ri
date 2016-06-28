#vim-ref-ri
A [vim-ref](https://github.com/thinca/vim-ref) source for ri.

##usage

###vim-ref

```vim
:Ref ri Net::HTTP

" instance method
:Ref ri Net::HTTP#get

" class method
:Ref ri Net::HTTP.new
```

###Unite.vim

```vim
:Unite ref/ri
```

##arguments
This source accepts the argument of the following three forms.

- class
- class.class_method
- class#instance_method

##customizing
<dl>
  <dt>g:ref_ri_cmd</dt>
  <dd>Specifies the ri command.</dd>
  <dt>g:ref_ri_use_cache</dt>
  <dd>
    Cache the classes and methods at the time of completion.
    The deault value is 0.
  </dt>
</dl>

Cache are not cleared automatically. You may be necessary to following settings.

```ruby
# lib/rubygems_plugin.rb

Gem.post_install do
  cache_file = File.expand_path '~/.cache/vim-ref/ri/classes'
  File.unlink cache_file is File.exist? cache_file
end<`0`>

Gem.post_uninstall do
  cache_file = File.expand_path '~/.cache/vim-ref/ri/classes'
  File.unlink cache_file is File.exist? cache_file
end
```

#Licence 
The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
