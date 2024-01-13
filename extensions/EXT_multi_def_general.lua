local logger = require("logger")
local u = require("lua_utils/utils")
local inspect = require("lua_utils.inspect")

local MultiDefinitionGeneral = {
    description = "This plugin helps to gather multiple descriptions from multiple dictionaries into one note",
    -- key: dictionary name as displayed in KOreader (received from dictionary's .ifo file, see bookname attribute)
    -- value: field on the note this dictionary entry should be sent to
    dict_field_map = {
        -- the below example sends dictionary entries from 'JMdict'  to the field 'SentEng' on the anki note
        -- ["JMdict Rev. 1.9"] = "SentEng",
       ["Cambridge Advanced Learner's Dictionary"] = "TranslEn",
       ["English-Russian short dictionary"] = "TranslRu",
    }
}

function MultiDefinitionGeneral:convert_dict_to_HTML(dictionaries)
    return self:convert_to_HTML {
        entries = dictionaries,
        class = "definition",
        build = function(entry, entry_template)
            -- TODO should we run the `definition_editor.lua` on this definition too?
            local def = entry.definition
            if entry.is_html then -- try adding dict name to opening div tag (if present)
                -- gsub wrapped in () so it only gives us the first result, and discards the index (2nd arg.)
                return (def:gsub("(<div)( ?)", string.format("%%1 dict=\"%s\"%%2", entry.dict), 1))
            end
            return entry_template:format(entry.dict, (def:gsub("\n", "<br>")))
        end
    }
end

function MultiDefinitionGeneral:run(note)

    local selected_dict = self.popup_dict.results[self.popup_dict.dict_index]
    -- map of note fields with all dictionary entries which should be combined and saved in said field
    local field_dict_map = u.defaultdict(function() return {} end)
    for idx, result in ipairs(self.popup_dict.results) do
        -- don't add definitions where the dict word does not match the selected dict's word
        -- if result.word == selected_dict.word then
       if true  then
            local is_selected = idx == self.popup_dict.dict_index
            local field = self.dict_field_map[result.dict]
            local field_defs = field_dict_map[field]
            -- make sure that the selected dictionary is always inserted in the beginning
            table.insert(field_defs, is_selected and 1 or #field_defs+1, result)
        else
            local skip_msg = "Skipping %s dict entry: kana word '%s' ~= selected dict word '%s'"
            logger.info(skip_msg:format(result.dict, result.word, selected_dict.word))
        end
    end
    for field, dicts in pairs(field_dict_map) do
        note.fields[field] = self:convert_dict_to_HTML(dicts)
    end
    return note
end

return MultiDefinitionGeneral
