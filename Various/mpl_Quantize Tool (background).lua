-- @description QuantizeTool
-- @version 2.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about Script for manipulating REAPER objects time and values
-- @provides
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_GUI.lua
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_MOUSE.lua
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_data.lua
--    mpl_QuantizeTool_functions/mpl_QuantizeTool_obj.lua
--    mpl_QuantizeTool_presets/mpl_QuantizeTool - Getting started.pdf
--    [main] mpl_QuantizeTool_presets/mpl_QuantizeTool preset - default.lua
--    [main] mpl_QuantizeTool_presets/mpl_QuantizeTool preset - (MPL) Quantize item positions to project grid (no GUI).lua
--    [main] mpl_QuantizeTool_presets/mpl_QuantizeTool preset - (MPL) Align selected items to edit cursor.lua
--    [main] mpl_QuantizeTool_presets/mpl_QuantizeTool preset - (MPL) Create selected envelope points from selected items.lua
--    [main] mpl_QuantizeTool_presets/mpl_QuantizeTool preset - (MPL) Quantize item midi notes to project grid (no GUI).lua
--    mpl_QuantizeTool_presets/(MPL) Align selected items to edit cursor.qt
--    mpl_QuantizeTool_presets/(MPL) Create selected envelope points from selected items.qt
--    mpl_QuantizeTool_presets/(MPL) Quantize item positions to project grid (no GUI).qt
--    mpl_QuantizeTool_presets/(MPL) Quantize item midi notes to project grid (no GUI).qt
-- @changelog
--    # add ReaPack @version tag to self-build preset scripts
     
  local vrs = 'v2.03'
  --NOT gfx NOT reaper
  

  
  --  INIT -------------------------------------------------
  local conf = {}  
  local refresh = { GUI_onStart = true, 
                    GUI = false, 
                    GUI_minor = false,
                    data = false,
                    data_proj = false, 
                    conf = false}
  local mouse = {}
  local data = {}
  local obj = {}
   strategy = {}
  
  local info = debug.getinfo(1,'S');  
  local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
  obj.script_path = script_path
  ---------------------------------------------------   
  function Main_RefreshExternalLibs()     -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua    
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_GUI.lua")
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_MOUSE.lua")  
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_obj.lua")  
    dofile(script_path .. "mpl_QuantizeTool_functions/mpl_QuantizeTool_data.lua")  
  end  
  --------------------------------------------------------------------
  function LoadStrategy_Default()
    local t = {name = 'default', 
    
    -- reference -----------------------
      -- positions
        ref_positions = 1,
        ref_selitems = 0, --&2 snap offset -- &4 handle grouping
        ref_envpoints = 1, -- &2 all selected
        ref_midi = 0, --&2 Selected items
        ref_midi_msgflag = 1, --&2 note off
        ref_strmarkers = 0, 
        ref_editcur = 0 ,    
        ref_marker = 0,   
        ref_timemarker = 0  ,
        
        ref_grid = 2 ,   -- &2 current &4 triplet &8 swing
        ref_grid_val = 1, 
        ref_grid_sw = 0,  
          
      -- pattern
        ref_pattern = 0,
        ref_pattern_gensrc = 1,
        ref_pattern_len = 4,
        ref_pattern_name = 'last_touched',
        
    -- source -----------------------
      -- positions
        src_positions = 1,
        src_selitems = 1,
        src_envpoints = 0,
        src_midi = 0 ,
        src_midi_msgflag = 1,--&2 note off
        src_strmarkers = 0,
         
    -- action -----------------------
      --  align
        act_action = 1 , 
        act_alignflag = 0, -- &1= linked knobs
      -- init
        act_initcatchref = 1 ,   
        act_initcatchsrc = 0 ,
        act_initact = 0  ,
        act_initapp = 0,
        act_initgui = 1,
        
    -- execute -----------------------
      exe_val1 = 0, -- align=strength
      exe_val2 = 0, -- align=value
      exe_val3 = 0, -- align=inclwithin/0-disabled
      exe_val4 = 0, -- align=exclwithin/0-disabled
      
      }
    return t
  end
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
            -- globals
            mb_title = 'QuantizeTool',
            ES_key = 'MPL_QuantizeTool',
            wind_x =  50,
            wind_y =  50,
            wind_w =  450,
            wind_h =  450,
            dock =    0,
            dock2 =    0, -- set manually docked state
            
            -- mouse
            mouse_wheel_res = 960,
            activetab = 1, 
            
            -- data
            app_on_strategy_change = 0,
            app_on_slider_click = 1,
            iterationlim = 30000, -- deductive brutforce
            
            }
    return t
  end  
  ---------------------------------------------------    
  function run()
    obj.clock = os.clock()
    
    MOUSE(conf, obj, data, refresh, mouse)
    CheckUpdates(obj, conf, refresh)
    
  
    if refresh.conf == true then 
      ExtState_Save(conf)
      refresh.conf = nil 
    end

    if refresh.GUI == true or refresh.GUI_onStart == true then            OBJ_Update              (conf, obj, data, refresh, mouse,strategy) end  
    if refresh.GUI_minor == true then refresh.GUI = true end
    GUI_draw               (conf, obj, data, refresh, mouse, strategy)    
                                               
 
    ShortCuts(conf, obj, data, refresh, mouse)
    if mouse.char >= 0 and mouse.char ~= 27 
      then defer(run) else atexit(gfx.quit) end
  end
    
  
  
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
  ---------------------------------------------------
  function CheckReaperVrs(rvrs) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
      return
     else
      return true
    end
  end
--------------------------------------------------------------------
  function LoadStrategy(conf, strategy, force_default)
    obj.is_strategy_dirty = false
    
    local cur_strat = GetExtState( conf.ES_key, 'ext_strategy_name' )
    local ext_state = GetExtState( conf.ES_key, 'ext_state' )
    local ext_state = ext_state and ext_state=='1' 
    
    -- load defaults
      local def_t = LoadStrategy_Default()
      for key in pairs(def_t) do strategy[key] = def_t[key] end
      if force_default or (ext_state and cur_strat == 'default') then 
        SaveStrategy(conf, strategy, 1, true)
        return 
      end
      
    -- check ext state
      SetExtState( conf.ES_key, 'ext_state', 0, false )
      if ext_state and cur_strat ~= 'default' then
        local preset_path = obj.script_path .. 'mpl_QuantizeTool_presets/'..cur_strat..'.qt'
        local f = io.open(preset_path, 'r')
        if f then 
          f:close()
          LoadStrategy_Parse(strategy, preset_path )
          return
         else
          MB('External strategy not found', 'QuantizeTool',0)
        end
      end
    
    -- load last saved
      local preset_path = obj.script_path .. 'mpl_QuantizeTool_presets/last saved.qt'
      local f = io.open(preset_path, 'r')
      if f then 
        f:close()
        LoadStrategy_Parse(strategy, preset_path )
        obj.is_strategy_dirty = true
      end
    
      
  end
  --------------------------------------------------------------------
  function SaveStrategy(conf, strategy, flag, lastsaved)
  
    if (strategy.name == 'default' or strategy.name == '') and not lastsaved then return end
    local name = strategy.name
    if lastsaved then name = 'last saved' end
    
    name = name:gsub('*','')
    local out_fp = script_path .. "mpl_QuantizeTool_presets/"..name..'.qt'
    local out_str = '//Preset for MPL`s QuantizeTool v2\n'
    for val in spairs(strategy) do out_str = out_str..'\n'..val..'='..strategy[val] end
    
    if flag&1==1 then
      -- save to file
        local f = io.open(out_fp, 'w')
        if f then
          f:write(out_str)
          f:close()
        end
    end
    
    if flag&2==2 then
      -- save to action list
        local out_fp_script = script_path .. "mpl_QuantizeTool_presets/mpl_QuantizeTool preset - "..name..'.lua'
        local out_str = 
[[
-- @description QuantizeTool preset - ]]..strategy.name..[[
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @version 1.0

-- generated from MPL QuantizeTool v2

reaper.SetExtState("]].. conf.ES_key..'", "ext_strategy_name", "'..strategy.name..[[",false)
reaper.SetExtState("]].. conf.ES_key..[[","ext_state",1,false)
]]                                                          
        local f = io.open(out_fp_script, 'w')
        f:write(out_str)
        f:close()    
        AddRemoveReaScript( true, 0, out_fp_script, true )      
    end                                    
  end  
  --------------------------------------------------------------------
  function LoadStrategy_Parse(strategy, strat_fp)
    
    -- read content
      local f, content = io.open(strat_fp, 'r')
      if  f then  content = f:read('a') f:close()  else   return     end    
      if content then 
        for line in content:gmatch('[^\r\n]+') do
          if line:match('=') then
            local val = line:match('=(.*)')
            if tonumber(val) then val = tonumber(val) end
            local key = line:match('(.*)='):gsub('%s','')
            strategy[key] = val
          end
        end
      end
      
  end
--------------------------------------------------------------------
  function main()
        conf.dev_mode = 0
        conf.vrs = vrs
        Main_RefreshExternalLibs()
        ExtState_Load(conf)
        LoadStrategy(conf, strategy)
        if strategy.act_initcatchref == 1 then  Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy) end
        if strategy.act_initcatchsrc == 1 then  Data_ApplyStrategy_source   (conf, obj, data, refresh, mouse, strategy) end
        if strategy.act_initact == 1 then Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy) end
        if strategy.act_initapp == 1 then Data_Execute(conf, obj, data, refresh, mouse, strategy) end
        if strategy.act_initgui == 1 then 
          gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                    conf.wind_w, 
                    conf.wind_h, 
                    conf.dock2, conf.wind_x, conf.wind_y)
          OBJ_init(obj)
          OBJ_Update(conf, obj, data, refresh, mouse,strategy) 
          run()  
        end
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetFormattedGrid') 
  local ret2 = CheckReaperVrs(5.95)    
  if ret and ret2 then main() end
