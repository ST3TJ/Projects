uih.recursive_visibility = function(tbl, up_value)
    for key, item in pairs(tbl) do
        local master = tbl.master
        local master_value = up_value

        local item_type = type(item)
        local master_type = master and master:get_type() or ""

        local name = tostring(key):lower()
        local is_master = name == "master"
        local is_list = (master_type == "combo" or master_type == "list")
        local is_multi = master_type == "multi_combo"

        if master then
            master_value = master:get()
        end

        if is_list then
            master_value = master:get_items()[master_value + 1]:lower() == name or tostring(master_value) == name
        elseif is_multi then
            local master_items = master:get_items()
            local master_values = master:get()
            for i = 1, #master_items do
                local master_item = master_items[i]:lower()

                if master_item == name then
                    master_value = master_values[i - 1]
                end
            end
        end

        if item_type == "userdata" then
            item:set_visible(is_master and up_value or up_value and master_value)
        elseif item_type == "table" then
            uih.recursive_visibility(item, master_value and up_value)
        end
    end
end
