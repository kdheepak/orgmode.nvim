local mock = require('luassert.mock')
local OrgmodeOmniCompletion = require('orgmode.org.autocompletion.omni')
local Files = require('orgmode.parser.files')

local function mock_line(api, content)
  api.nvim_get_current_line.returns(content)
  api.nvim_call_function.returns(content:len() + 5)
end

describe('Autocompletion', function()
  it('should properly find start offset for omni autocompletion', function()
    local api = mock(vim.api, true)
    mock_line(api, '')
    local result = OrgmodeOmniCompletion(1, '')
    assert.are.same(0, result)

    mock_line(api, '* ')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(2, result)

    mock_line(api, '* TO')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(2, result)

    mock_line(api, '* TODO')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(2, result)

    mock_line(api, '* TODO some text ')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(17, result)

    mock_line(api, '* TODO tags goes at the end :')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(28, result)

    mock_line(api, '* TODO tags goes at the end :SOMET')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(28, result)
    mock_line(api, '* TODO tags goes at the end :SOMETAG:')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(36, result)

    mock_line(api, '#')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(0, result)

    mock_line(api, '#+')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(0, result)

    mock_line(api, '#+AR')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(0, result)

    mock_line(api, ':')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(0, result)

    mock_line(api, '  :')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(2, result)

    mock_line(api, '  :PROP')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(2, result)

    mock_line(api, '  :PROPERTI')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(2, result)

    mock_line(api, '  [[')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(4, result)

    mock_line(api, '  [[*some')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(4, result)

    mock_line(api, '  [[#val')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(4, result)

    mock_line(api, '  [[test')
    result = OrgmodeOmniCompletion(1, '')
    assert.are.same(4, result)

    mock.revert(api)
  end)

  it('should properly return results for base', function()
    local api = mock(vim.api, true)
    mock_line(api, '')
    local result = OrgmodeOmniCompletion(0, '')
    assert.are.same({}, result)

    -- Metadata
    result = OrgmodeOmniCompletion(0, 'D')
    assert.are.same({
      { menu = '[Org]', word = 'DEADLINE:' },
    }, result)

    -- Properties
    result = OrgmodeOmniCompletion(0, ':')
    local props = {
      { menu = '[Org]', word = ':PROPERTIES:' },
      { menu = '[Org]', word = ':END:' },
      { menu = '[Org]', word = ':LOGBOOK:' },
      { menu = '[Org]', word = ':STYLE:' },
      { menu = '[Org]', word = ':REPEAT_TO_STATE:' },
      { menu = '[Org]', word = ':CUSTOM_ID:' },
      { menu = '[Org]', word = ':CATEGORY:' },
    }
    assert.are.same(props, result)

    result = OrgmodeOmniCompletion(0, ':C')
    assert.are.same({
      { menu = '[Org]', word = ':CUSTOM_ID:' },
      { menu = '[Org]', word = ':CATEGORY:' },
    }, result)

    result = OrgmodeOmniCompletion(0, ':CA')
    assert.are.same({
      { menu = '[Org]', word = ':CATEGORY:' },
    }, result)

    -- Directives
    result = OrgmodeOmniCompletion(0, '#')
    local directives = {
      { menu = '[Org]', word = '#+TITLE' },
      { menu = '[Org]', word = '#+AUTHOR' },
      { menu = '[Org]', word = '#+EMAIL' },
      { menu = '[Org]', word = '#+NAME' },
      { menu = '[Org]', word = '#+FILETAGS' },
      { menu = '[Org]', word = '#+ARCHIVE' },
      { menu = '[Org]', word = '#+OPTIONS' },
      { menu = '[Org]', word = '#+BEGIN_SRC' },
      { menu = '[Org]', word = '#+END_SRC' },
      { menu = '[Org]', word = '#+BEGIN_EXAMPLE' },
      { menu = '[Org]', word = '#+END_EXAMPLE' },
    }
    assert.are.same(directives, result)

    result = OrgmodeOmniCompletion(0, '#+')
    assert.are.same(directives, result)

    result = OrgmodeOmniCompletion(0, '#+B')
    assert.are.same({
      { menu = '[Org]', word = '#+BEGIN_SRC' },
      { menu = '[Org]', word = '#+BEGIN_EXAMPLE' },
    }, result)

    -- Headline
    mock_line(api, '* ')
    result = OrgmodeOmniCompletion(0, '')
    assert.are.same({
      { menu = '[Org]', word = 'TODO' },
      { menu = '[Org]', word = 'DONE' },
    }, result)

    mock_line(api, '* T')
    result = OrgmodeOmniCompletion(0, 'T')
    assert.are.same({
      { menu = '[Org]', word = 'TODO' },
    }, result)

    Files.tags = { 'OFFICE', 'PRIVATE' }
    mock_line(api, '* TODO tags go at the end :')
    result = OrgmodeOmniCompletion(0, ':')
    assert.are.same({
      { menu = '[Org]', word = ':OFFICE:' },
      { menu = '[Org]', word = ':PRIVATE:' },
    }, result)

    mock_line(api, '* TODO tags go at the end :')
    result = OrgmodeOmniCompletion(0, ':OFF')
    assert.are.same({
      { menu = '[Org]', word = ':OFFICE:' },
    }, result)

    mock_line(api, '* TODO tags go at the end :OFFICE:')
    result = OrgmodeOmniCompletion(0, ':')
    assert.are.same({
      { menu = '[Org]', word = ':OFFICE:' },
      { menu = '[Org]', word = ':PRIVATE:' },
    }, result)

    mock_line(api, '#+FILETAGS: ')
    result = OrgmodeOmniCompletion(0, '')
    assert.are.same({}, result)

    mock_line(api, '#+FILETAGS: :')
    result = OrgmodeOmniCompletion(0, ':')
    assert.are.same({
      { menu = '[Org]', word = ':OFFICE:' },
      { menu = '[Org]', word = ':PRIVATE:' },
    }, result)

    -- TODO: Add hyperlinks test

    mock.revert(api)
  end)
end)
