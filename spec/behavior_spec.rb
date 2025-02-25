# frozen_string_literal: true

require "htmlbeautifier"

describe HtmlBeautifier do
  it "ignores HTML fragments in embedded ERB" do
    source = code <<~HTML
      <div>
        <%= a[:b].gsub("\n","<br />\n") %>
      </div>
    HTML
    expected = code <<~HTML
      <div>
        <%= a[:b].gsub("\n","<br />\n") %>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "allows < in an attribute" do
    source = code <<~HTML
      <div ng-show="foo < 1">
      <p>Hello</p>
      </div>
    HTML
    expected = code <<~HTML
      <div ng-show="foo < 1">
        <p>Hello</p>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "allows > in an attribute" do
    source = code <<~HTML
      <div ng-show="foo > 1">
      <p>Hello</p>
      </div>
    HTML
    expected = code <<~HTML
      <div ng-show="foo > 1">
        <p>Hello</p>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents within <script>" do
    source = code <<~HTML
      <script>
      function(f) {
          g();
          return 42;
      }
      </script>
    HTML
    expected = code <<~HTML
      <script>
        function(f) {
            g();
            return 42;
        }
      </script>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "does not indent blank lines in scripts" do
    source   = "<script>\n  function(f) {\n\n  }\n</script>"
    expected = "<script>\n  function(f) {\n\n  }\n</script>"
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "handles self-closing HTML fragments in javascript: <img /> (bug repro)" do
    source = code <<-ERB
    <div class="<%= get_class %>" ></div>
    <script>
      var warning_message = "<%= confirm_data %>";
      $('#img').html('<img src="/myimg.jpg" />')
      $('#errors').html('<div class="alert alert-danger" role="alert">' + error_message + '</div>')
    </script>
    ERB

    expect(described_class.beautify(source, stop_on_errors: true)).to eq(source)
  end

  it "indents only the first line of code inside <script> or <style> and retains the other lines' indents relative to the first line" do
    source = code <<~HTML
      <script>
        function(f) {
            g();
            return 42;
        }
      </script>
      <style>
                    .foo{ margin: 0; }
                    .bar{
                      padding: 0;
                      margin: 0;
                    }
      </style>
      <style>
        .foo{ margin: 0; }
                    .bar{
                      padding: 0;
                      margin: 0;
                    }
      </style>
    HTML
    expected = code <<~HTML
      <script>
        function(f) {
            g();
            return 42;
        }
      </script>
      <style>
        .foo{ margin: 0; }
        .bar{
          padding: 0;
          margin: 0;
        }
      </style>
      <style>
        .foo{ margin: 0; }
                    .bar{
                      padding: 0;
                      margin: 0;
                    }
      </style>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "retains empty <script> and <style> blocks" do
    source = code <<~HTML
      <script>

      </script>
      <style>

      </style>
    HTML
    expected = code <<~HTML
      <script></script>
      <style></style>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "trims blank lines around scripts" do
    source = code <<~HTML
      <script>

        f();

      </script>
    HTML
    expected = code <<~HTML
      <script>
        f();
      </script>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "removes trailing space from script lines" do
    source = "<script>\n  f();  \n</script>"
    expected = "<script>\n  f();\n</script>"
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "leaves empty scripts as they are" do
    source = %{<script src="/foo.js" type="text/javascript" charset="utf-8"></script>}
    expect(described_class.beautify(source)).to eq(source)
  end

  it "removes whitespace from script tags containing only whitespace" do
    source = "<script>\n</script>"
    expected = "<script></script>"
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "ignores case of <script> tag" do
    source = code <<~HTML
      <SCRIPT>

      // code

      </SCRIPT>
    HTML
    expected = code <<~HTML
      <SCRIPT>
        // code
      </SCRIPT>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents within <style>" do
    source = code <<~HTML
      <style>
      .foo{ margin: 0; }
      .bar{
        padding: 0;
        margin: 0;
      }
      </style>
    HTML
    expected = code <<~HTML
      <style>
        .foo{ margin: 0; }
        .bar{
          padding: 0;
          margin: 0;
        }
      </style>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "trims blank lines around styles" do
    source = code <<~HTML
      <style>

        .foo{ margin: 0; }

      </style>
    HTML
    expected = code <<~HTML
      <style>
        .foo{ margin: 0; }
      </style>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "removes trailing space from style lines" do
    source = "<style>\n  .foo{ margin: 0; }  \n</style>"
    expected = "<style>\n  .foo{ margin: 0; }\n</style>"
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "ignores case of <style> tag" do
    source = code <<~HTML
      <STYLE>

      .foo{ margin: 0; }

      </STYLE>
    HTML
    expected = code <<~HTML
      <STYLE>
        .foo{ margin: 0; }
      </STYLE>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents <div>s containing standalone elements" do
    source = code <<~HTML
      <div>
      <div>
      <img src="foo" alt="" />
      </div>
      <div>
      <img src="foo" alt="" />
      </div>
      </div>
    HTML
    expected = code <<~HTML
      <div>
        <div>
          <img src="foo" alt="" />
        </div>
        <div>
          <img src="foo" alt="" />
        </div>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "does not break line on embedded code within <script> opening tag" do
    source = %{<script src="<%= path %>" type="text/javascript"></script>}
    expect(described_class.beautify(source)).to eq(source)
  end

  it "does not break line on embedded code within normal element" do
    source = %{<img src="<%= path %>" alt="foo" />}
    expect(described_class.beautify(source)).to eq(source)
  end

  it "outdents else" do
    source = code <<~ERB
      <% if @x %>
      Foo
      <% else %>
      Bar
      <% end %>
    ERB
    expected = code <<~ERB
      <% if @x %>
        Foo
      <% else %>
        Bar
      <% end %>
    ERB
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents with hyphenated ERB tags" do
    source = code <<~ERB
      <%- if @x -%>
      <%- @ys.each do |y| -%>
      <p>Foo</p>
      <%- end -%>
      <%- elsif @z -%>
      <hr />
      <%- end -%>
    ERB
    expected = code <<~ERB
      <%- if @x -%>
        <%- @ys.each do |y| -%>
          <p>Foo</p>
        <%- end -%>
      <%- elsif @z -%>
        <hr />
      <%- end -%>
    ERB
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents case statements" do
    source = code <<~ERB
      <div>
        <% case @x %>
        <% when :a %>
        a
        <% when :b %>
        b
        <% else %>
        c
        <% end %>
      </div>
    ERB
    expected = code <<~ERB
      <div>
        <% case @x %>
        <% when :a %>
          a
        <% when :b %>
          b
        <% else %>
          c
        <% end %>
      </div>
    ERB
    expect(described_class.beautify(source)).to eq(expected)

  end

  it "stays indented within <details> with Boolean attribute handled by ERB" do
    source = code <<~ERB
      <details <%= "open" if opened %>>
        <summary>Hello</summary>
        <div>
          <table>
            <% items.each do |item| %>
              <tr>
                <td>
                  <code><%= item %></code>
                </td>
              </tr>
            <% end %>
          </table>
        </div>
      </details>
    ERB
    expect(described_class.beautify(source)).to eq(source)
  end

  it "does not indent after comments" do
    source = code <<~HTML
      <!-- This is a comment -->
      <!-- So is this -->
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "does not indent one-line IE conditional comments" do
    source = code <<~HTML
      <!--[if lt IE 7]><html lang="en-us" class="ie6"><![endif]-->
      <!--[if IE 7]><html lang="en-us" class="ie7"><![endif]-->
      <!--[if IE 8]><html lang="en-us" class="ie8"><![endif]-->
      <!--[if gt IE 8]><!--><html lang="en-us"><!--<![endif]-->
        <body>
        </body>
      </html>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "indents inside IE conditional comments" do
    source = code <<~HTML
      <!--[if IE 6]>
      <link rel="stylesheet" href="/stylesheets/ie6.css" type="text/css" />
      <![endif]-->
      <!--[if IE 5]>
      <link rel="stylesheet" href="/stylesheets/ie5.css" type="text/css" />
      <![endif]-->
    HTML
    expected = code <<~HTML
      <!--[if IE 6]>
        <link rel="stylesheet" href="/stylesheets/ie6.css" type="text/css" />
      <![endif]-->
      <!--[if IE 5]>
        <link rel="stylesheet" href="/stylesheets/ie5.css" type="text/css" />
      <![endif]-->
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "does not indent after doctype" do
    source = code <<~HTML
      <!DOCTYPE html>
      <html>
      </html>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "does not indent after void HTML elements" do
    source = code <<~HTML
      <meta>
      <input id="id">
      <br>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "ignores case of void elements" do
    source = code <<~HTML
      <META>
      <INPUT id="id">
      <BR>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "does not treat <colgroup> as standalone" do
    source = code <<~HTML
      <colgroup>
        <col style="width: 50%;">
      </colgroup>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "does not modify content of <pre>" do
    source = code <<~HTML
      <div>
        <pre>   Preformatted   text

                should  <em>not  be </em>
                      modified,
                ever!

        </pre>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "adds a single newline after block elements" do
    source = code <<~HTML
      <section><h1>Title</h1><p>Lorem <em>ipsum</em></p>
      <ol>
        <li>First</li><li>Second</li></ol>


      </section>
    HTML
    expected = code <<~HTML
      <section>
        <h1>Title</h1>
        <p>Lorem <em>ipsum</em></p>
        <ol>
          <li>First</li>
          <li>Second</li>
        </ol>
      </section>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "does not modify content of <textarea>" do
    source = code <<~HTML
      <div>
        <textarea>   Preformatted   text

                should  <em>not  be </em>
                      modified,
                ever!

        </textarea>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(source)
  end

  it "adds newlines around <pre>" do
    source = %{<section><pre>puts "Allons-y!"</pre></section>}
    expected = code <<~HTML
      <section>
        <pre>puts "Allons-y!"</pre>
      </section>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "adds newline after <br>" do
    source = %{<p>Lorem ipsum<br>dolor sit<br />amet,<br/>consectetur.</p>}
    expected = code <<~HTML
      <p>Lorem ipsum<br>
        dolor sit<br />
        amet,<br/>
        consectetur.</p>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents after control expressions without optional `do` keyword" do
    source = code <<~ERB
      <% for value in list %>
      Lorem ipsum
      <% end %>
      <% until something %>
      Lorem ipsum
      <% end %>
      <% while something_else %>
      Lorem ipsum
      <% end %>
    ERB
    expected = code <<~ERB
      <% for value in list %>
        Lorem ipsum
      <% end %>
      <% until something %>
        Lorem ipsum
      <% end %>
      <% while something_else %>
        Lorem ipsum
      <% end %>
    ERB
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents general self-closing tags" do
    source = code <<~HTML
      <div>
      <svg>
      <path d="M150 0 L75 200 L225 200 Z" />
      <circle cx="50" cy="50" r="40" />
      </svg>
      <br>
      <br/>
      <p>
      <foo />
      </p>
      </div>
    HTML
    expected = code <<~HTML
      <div>
        <svg>
          <path d="M150 0 L75 200 L225 200 Z" />
          <circle cx="50" cy="50" r="40" />
        </svg>
        <br>
        <br/>
        <p>
          <foo />
        </p>
      </div>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "removes excess indentation on next line after text" do
    source = code <<~HTML
      Lorem ipsum
                      <br>
      Lorem ipsum
                      <em>
        Lorem ipsum
                      </em>
    HTML
    expected = code <<~HTML
      Lorem ipsum
      <br>
      Lorem ipsum
      <em>
        Lorem ipsum
      </em>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  it "indents subsequent lines of multiline text" do
    source = code <<~HTML
      <p>
      Lorem
      Lorem
      Lorem
      </p>
    HTML
    expected = code <<~HTML
      <p>
        Lorem
        Lorem
        Lorem
      </p>
    HTML
    expect(described_class.beautify(source)).to eq(expected)
  end

  context "when keep_blank_lines is 0" do
    it "removes all blank lines" do
      source = code <<~HTML
        <h1>Lorem</h1>



        <p>Ipsum</p>
      HTML
      expected = code <<~HTML
        <h1>Lorem</h1>
        <p>Ipsum</p>
      HTML
      expect(described_class.beautify(source, keep_blank_lines: 0)).to eq(expected)
    end
  end

  context "when keep_blank_lines is 1" do
    it "removes all blank lines but 1" do
      source = code <<~HTML
        <h1>Lorem</h1>



        <p>Ipsum</p>
      HTML
      expected = code <<~HTML
        <h1>Lorem</h1>

        <p>Ipsum</p>
      HTML
      expect(described_class.beautify(source, keep_blank_lines: 1)).to eq(expected)
    end

    it "does not add blank lines" do
      source = code <<~HTML
        <h1>Lorem</h1>
        <div>
          Ipsum
          <p>dolor</p>
        </div>
      HTML
      expect(described_class.beautify(source, keep_blank_lines: 1)).to eq(source)
    end

    it "does not indent blank lines" do
      source = code <<~HTML
        <div>
          Ipsum


          <p>dolor</p>
        </div>
      HTML
      expected = code <<~HTML
        <div>
          Ipsum

          <p>dolor</p>
        </div>
      HTML
      expect(described_class.beautify(source, keep_blank_lines: 1)).to eq(expected)
    end
  end

  context "when keep_blank_lines is 2" do
    it "removes all blank lines but 2" do
      source = code <<~HTML
        <h1>Lorem</h1>



        <p>Ipsum</p>
      HTML
      expected = code <<~HTML
        <h1>Lorem</h1>


        <p>Ipsum</p>
      HTML
      expect(described_class.beautify(source, keep_blank_lines: 2)).to eq(expected)
    end
  end
end
