require 'minitest/autorun'
require 'json'
require 'securerandom'

require_relative '../lib/moving_images/midrawing'
require_relative '../lib/moving_images/smigcommands'
require_relative '../lib/moving_images/smigobjectid'

include MovingImages
include CommandModule

# Test class for the SmigCommands class and it's objects
class TestSmigCommands < MiniTest::Unit::TestCase
  # Test the creation and the configuring of a smig command
  def test_configuring_smigcommand
    commands = SmigCommands.new
    commands.stoponfailure = false
    commands.informationreturned = :lastcommandresult
    commands.saveresultstype = :jsonfile
    commands.saveresultsto = '~/Documents/commandresult.json'
    new_json = commands.commandshash.to_json
    old_json = '{"stoponfailure":false,"returns":"lastcommandresult",'\
    '"saveresultstype":"jsonfile",'\
    '"saveresultsto":"~/Documents/commandresult.json"}'
    assert new_json.eql?(old_json), '1. SmigCommands produced different json'
  end

  # Test the creation of a SmigCommands object and adding commands to it.
  def test_addingcommands_tosmigcommands
    commands = SmigCommands.new
    bitmap_size = MIShapes.make_size(100, 100)
    bitmap_object = commands.make_createbitmapcontext(size: bitmap_size,
                                                      name: 'TestSmigCommands')
    window_rect = MIShapes.make_rectangle(width: 200, height: 200)
    commands.make_createwindowcontext(rect: window_rect,
                                      borderlesswindow: false,
                                      name: 'TestSmigCommands.addingcommands')
    draw_element = CommandModule.make_drawelement(bitmap_object,
                                                  drawinstructions: {})
    commands.add_command(draw_element)
    new_json = commands.commandshash.to_json
    old_json = '{"commands":[{"command":"create","objecttype":"bitmapcontext",'\
    '"objectname":"TestSmigCommands","size":{"width":100,"height":100},'\
    '"preset":"AlphaPreMulFirstRGB8bpcInt"},{"command":"create",'\
    '"objecttype":"nsgraphicscontext",'\
    '"objectname":"TestSmigCommands.addingcommands",'\
    '"rect":{"origin":{"x":0.0,"y":0.0},"size":{"width":200,"height":200}},'\
    '"borderlesswindow":false},{"command":"drawelement",'\
    '"receiverobject":{"objecttype":"bitmapcontext",'\
    '"objectname":"TestSmigCommands"},"drawinstructions":{}}],'\
    '"cleanupcommands":[{"command":"close","receiverobject":{"objecttype":'\
    '"bitmapcontext","objectname":"TestSmigCommands"}},'\
    '{"command":"close","receiverobject":{"objecttype":"nsgraphicscontext",'\
    '"objectname":"TestSmigCommands.addingcommands"}}]}'
    assert new_json.eql?(old_json), '2. SmigCommands produced different json'
  end
  # This is in no way complete. Still to do
  # * Clearing of configuration and commands
  # * clearing of commands
end

# The CommandModule module methods need to be tested.
# The SmigHelper methods need to be tested.

# The creation of all sort of command objects.
class TestObjectCommands < MiniTest::Unit::TestCase
  def test_making_objectcommands1
    importer_object = { objecttype: :imageimporter, objectname: 'test.object' }
    exporter_object = { objecttype: :imageexporter,
                        objectname: 'export.object' }
    general_object = { objectreference: 0 }
    close_command = CommandModule.make_close(importer_object)
    new_json = close_command.commandhash.to_json
    old_json = '{"command":"close","receiverobject":'\
    '{"objecttype":"imageimporter","objectname":"test.object"}}'
    assert new_json.eql?(old_json), 'CommandModule.make_close different JSON'
    export_command = CommandModule.make_export(exporter_object)
    new_json = export_command.commandhash.to_json
    old_json = '{"command":"export","receiverobject":'\
    '{"objecttype":"imageexporter","objectname":"export.object"}}'
    assert new_json.eql?(old_json), 'CommandModule.make_export different JSON'
    makesnapshot_command = CommandModule.make_snapshot(
                                        general_object,
                                        snapshottype: :takesnapshot)
    new_json = makesnapshot_command.commandhash.to_json
    old_json = '{"command":"snapshot","receiverobject":{"objectreference":0},'\
    '"snapshotaction":"takesnapshot"}'
    assert new_json.eql?(old_json), 'CommandModule.make_snapshot different JSON'
  end
  # This is no way complete
  
  def test_make_addimagecommand
    exporter_object = { objecttype: :imageexporter,
                        objectname: 'exporter.object' }
    importer_object = { objecttype: :imageimporter,
                        objectname: 'importer.object' }
    context_object = { objectreference: 0 }
    addimage_command = CommandModule.make_addimage(exporter_object,
                                                   importer_object,
                                                   imageindex: 1,
                                                   grabmetadata: true)
    new_json = addimage_command.commandhash.to_json
    old_json = '{"command":"addimage","receiverobject":'\
    '{"objecttype":"imageexporter","objectname":"exporter.object"},'\
    '"secondaryobject":{"objecttype":"imageimporter",'\
    '"objectname":"importer.object"},"secondaryimageindex":1,'\
    '"grabmetadata":true}'
    assert new_json.eql?(old_json), 'CommandModule.make_addimage different JSON'
    
    # test simpler case where image comes from a context, no index, no metadata.
    addimage_command = CommandModule.make_addimage(exporter_object, 
                                                   context_object)
    new_json = addimage_command.commandhash.to_json
    old_json = '{"command":"addimage","receiverobject":'\
    '{"objecttype":"imageexporter","objectname":"exporter.object"},'\
    '"secondaryobject":{"objectreference":0}}'
    assert new_json.eql?(old_json), 'CommandModule.make_addimage different JSON'
  end
  
  def test_make_getpropertiescommand
    object = SmigIDHash.make_objectid(objecttype: :imageimporter,
                                      objectname: 'test.importer.object')
    jsonfile = '~/imageproperties.json'
    getproperties_command = CommandModule.make_get_objectproperties(
                                                     object,
                                                     imageindex: 0,
                                                     saveresultstype: :jsonfile,
                                                     saveresultsto: jsonfile)
    new_json = getproperties_command.commandhash.to_json
    old_json = '{"command":"getproperties","receiverobject":'\
    '{"objecttype":"imageimporter","objectname":"test.importer.object"},'\
    '"imageindex":0,"saveresultstype":"jsonfile",'\
    '"saveresultsto":"~/imageproperties.json"}'
    assert new_json.eql?(old_json), '1#make_get_objectproperties different JSON'
    pdf_object = SmigIDHash.make_objectid(objecttype: :pdfcontext,
                                          objectname: 'test.pdfcontext.object')
    getproperties_command = CommandModule.make_get_objectproperties(pdf_object)
    new_json = getproperties_command.commandhash.to_json
    old_json = '{"command":"getproperties","receiverobject":{"objecttype":'\
    '"pdfcontext","objectname":"test.pdfcontext.object"}}'
    assert new_json.eql?(old_json), '2#make_get_objectproperties different JSON'
  end
end