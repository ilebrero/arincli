# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


require 'test/unit'
require 'ticket_reg'
require 'rexml/document'
require 'tmpdir'
require 'fileutils'

class TicketRegTest < Test::Unit::TestCase

  @workd_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

  end

  def teardown

     FileUtils.rm_r( @work_dir )

  end

  def test_ticket_summary

    file = File.new( File.join( File.dirname( __FILE__ ) , "ticket-summary.xml" ), "r" )
    doc = REXML::Document.new( file )
    element = doc.root

    ticket = ARINcli::Registration::element_to_ticket element
    assert_equal( "20121012-X1", ticket.ticket_no )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.created_date )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.updated_date )
    assert_equal( "PENDING_REVIEW", ticket.ticket_status )
    assert_equal( "QUESTION", ticket.ticket_type )

    element = ARINcli::Registration::ticket_to_element ticket
    ticket = ARINcli::Registration::element_to_ticket element
    assert_equal( "20121012-X1", ticket.ticket_no )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.created_date )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.updated_date )
    assert_equal( "PENDING_REVIEW", ticket.ticket_status )
    assert_equal( "QUESTION", ticket.ticket_type )

  end

  def test_ticket_message
    file = File.new( File.join( File.dirname( __FILE__ ) , "ticket_message.xml" ), "r" )
    doc = REXML::Document.new( file )
    element = doc.root

    message = ARINcli::Registration::element_to_ticket_message element
    assert_equal( "NONE", message.category )
    assert_equal( "4", message.id )
    assert_equal( "2012-10-12T11:48:50.281-04:00", message.created_date )
    assert_equal( 2, message.text.size )
    assert_equal( "pleasee get back to me", message.text[0] )
    assert_equal( "you bone heads", message.text[1] )
    assert_equal( 1, message.attachments.size )
    assert_equal( "oracle-driver-license.txt", message.attachments[0].file_name )
    assert_equal( "8a8180b13a5597b1013a55a9d42f0007", message.attachments[0].id )

    element = ARINcli::Registration::ticket_message_to_element message
    message = ARINcli::Registration::element_to_ticket_message element
    assert_equal( "NONE", message.category )
    assert_equal( "4", message.id )
    assert_equal( "2012-10-12T11:48:50.281-04:00", message.created_date )
    assert_equal( 2, message.text.size )
    assert_equal( "pleasee get back to me", message.text[0] )
    assert_equal( "you bone heads", message.text[1] )
    assert_equal( 1, message.attachments.size )
    assert_equal( "oracle-driver-license.txt", message.attachments[0].file_name )
    assert_equal( "8a8180b13a5597b1013a55a9d42f0007", message.attachments[0].id )
  end

  def test_store_ticket_summary

    dir = File.join( @work_dir, "test_store_ticket_summary" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    mgr = ARINcli::Registration::TicketStorageManager.new c

    ticket = ARINcli::Registration::Ticket.new
    ticket.ticket_no="XB85"
    ticket.created_date="July 18, 2011"
    ticket.resolved_date="July 19, 2011"
    ticket.closed_date="July 20, 2011"
    ticket.updated_date="July 21, 2011"
    ticket.ticket_type="QUESTION"
    ticket.ticket_status="APPROVED"
    ticket.ticket_resolution="DENIED"

    mgr.put_ticket ticket, ARINcli::Registration::TicketStorageManager::SUMMARY_FILE_SUFFIX

    ticket2 = mgr.get_ticket "XB85", ARINcli::Registration::TicketStorageManager::SUMMARY_FILE_SUFFIX

    assert_equal( "XB85", ticket2.ticket_no )
    assert_equal( "July 18, 2011", ticket2.created_date )
    assert_equal( "July 19, 2011", ticket2.resolved_date )
    assert_equal( "July 20, 2011", ticket2.closed_date )
    assert_equal( "July 21, 2011", ticket2.updated_date )
    assert_equal( "QUESTION", ticket2.ticket_type )
    assert_equal( "APPROVED", ticket2.ticket_status )
    assert_equal( "DENIED", ticket2.ticket_resolution )

  end

  def test_store_ticket_message

    dir = File.join( @work_dir, "test_store_ticket_summary" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    mgr = ARINcli::Registration::TicketStorageManager.new c
    message = ARINcli::Registration::TicketMessage.new
    message.subject="Test"
    message.text=[ "This is line 1", "This is line 2" ]
    message.category="NONE"
    message.id="4"

    mgr.put_ticket_message "XB85", message
  end

  def test_out_of_date_ticket
    # initialize ticket_tree_manager
    dir = File.join( @work_dir, "test_out_of_date" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    tree_mgr = ARINcli::Registration::TicketTreeManager.new c

    # create a ticket and save it
    file = File.new( File.join( File.dirname( __FILE__ ) , "ticket-summary.xml" ), "r" )
    doc = REXML::Document.new( file )
    element = doc.root
    ticket = ARINcli::Registration::element_to_ticket element
    tree_mgr.put_ticket ticket
    tree_mgr.save

    # initialize new ticket_tree_manager
    tree_mgr = ARINcli::Registration::TicketTreeManager.new c

    # load ticket_tree_manager
    tree_mgr.load

    # compare ticket_node.updated_date to ticket_summary.updated_date
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert_equal( out_of_date, false )

    # change ticket date to 2013 and check again
    ticket.updated_date="2013-10-12T11:48:50.303-04:00"
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert_equal( out_of_date, true )

    # change ticket date to 2011 and check again
    ticket.updated_date="2011-10-12T11:48:50.303-04:00"
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert_equal( out_of_date, false )

    # now put the updated ticket in the tree manager and compare once more
    tree_mgr.put_ticket ticket
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert_equal( out_of_date, false )

    # now change the ticket no so it won't be found and compare
    ticket.ticket_no="20121012-X9999"
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert_equal( out_of_date, true )
  end

  def test_update_ticket
    # setup workspace
    dir = File.join( @work_dir, "test_update_ticket" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    # initialize the managers
    store_mgr = ARINcli::Registration::TicketStorageManager.new c
    tree_mgr = ARINcli::Registration::TicketTreeManager.new c
    tree_mgr.load

    # get a ticket_msgrefs
    summary_file = File.new( File.join( File.dirname( __FILE__ ) , "ticket-msgrefs.xml" ), "r" )
    doc = REXML::Document.new( summary_file )
    element = doc.root
    ticket = ARINcli::Registration::element_to_ticket element

    # put the ticket-msgrefs
    ticket_file = store_mgr.put_ticket ticket, ARINcli::Registration::TicketStorageManager::MSGREFS_FILE_SUFFIX
    ticket_node = tree_mgr.put_ticket ticket, ticket_file, "http://ticket/" + ticket.ticket_no

    # get a ticket messasge
    message_file = File.new( File.join( File.dirname( __FILE__ ) , "ticket_message.xml" ), "r" )
    doc = REXML::Document.new( message_file )
    element = doc.root
    message = ARINcli::Registration::element_to_ticket_message element

    # put the ticket message
    message_file = store_mgr.put_ticket_message ticket, message
    rest_ref = "http://ticket/" + ticket.ticket_no + "/" + message.id
    message_node = tree_mgr.put_ticket_message ticket_node, message, message_file, rest_ref

    # put the ticket attachment
    attachment = message.attachments[ 0 ]
    attachment_file = store_mgr.prepare_file_attachment ticket, message, attachment.id
    rest_ref = "http://ticket/" + ticket.ticket_no + "/" + message.id + "/" + attachment.id
    attachment_node =
        tree_mgr.put_ticket_attachment ticket_node, message_node, attachment, attachment_file, rest_ref
    f = File.open( attachment_file, "w" )
    f.puts( "1234" )
    f.puts( "5678" )
    f.close

    tree_mgr.save

    # Get new managers
    store_mgr2 = ARINcli::Registration::TicketStorageManager.new c
    tree_mgr2 = ARINcli::Registration::TicketTreeManager.new c
    tree_mgr2.load

    # test the ticket retrieval
    ticket_node2 = tree_mgr2.get_ticket_node ticket
    assert_equal( ticket_node2.handle, ticket.ticket_no )
    ticket2 = store_mgr2.get_ticket ticket
    assert_equal( ticket2.ticket_no, ticket.ticket_no )

    # get the message and retrieve
    assert_equal( ticket_node2.children.size, 1 )
    message_node2 = ticket_node.children[ 0 ]
    assert_equal( message_node2.handle, message.id )
    message2 = store_mgr2.get_ticket_message message_node2.data[ "storage_file" ]
    assert_equal( message.id, message2.id )

    # get the attachment
    assert_equal( message_node2.children.size, 1 )
    attachment_node2 = message_node2.children[ 0 ]
    f = File.open( attachment_node2.data[ "storage_file" ], "r" )
    lines = f.readlines
    assert_equal( lines.size, 2 )
    assert_equal( lines[ 0 ], "1234\n" )
    assert_equal( lines[ 1 ], "5678\n" )
    f.close
  end

  def test_sort_messages
    ticket_node = ARINcli::DataNode.new( "ticket", "X1" )
    mesg_node5 = ARINcli::DataNode.new( "mesg5", "5", nil, {} )
    mesg_node5.data[ "created_date" ] = "2011-10-12T11:48:50.303-04:00"
    ticket_node.add_child( mesg_node5 )
    mesg_node1 = ARINcli::DataNode.new( "mesg1", "1", nil, {} )
    mesg_node1.data[ "created_date" ] = "2011-10-12T11:48:50.303-04:00"
    ticket_node.add_child( mesg_node1 )
    mesg_node2 = ARINcli::DataNode.new( "mesg2", "2", nil, {} )
    mesg_node2.data[ "created_date" ] = "2011-10-12T11:48:50.303-04:00"
    ticket_node.add_child( mesg_node2 )
    mesg_node3 = ARINcli::DataNode.new( "mesg3", "3", nil, {} )
    mesg_node3.data[ "created_date" ] = "2010-10-12T11:48:50.303-04:00"
    ticket_node.add_child( mesg_node3 )
    mesg_node4 = ARINcli::DataNode.new( "mesg4", "4", nil, {} )
    mesg_node4.data[ "created_date" ] = "2010-10-12T11:48:50.303-04:00"
    ticket_node.add_child( mesg_node4 )

    dir = File.join( @work_dir, "test_sort_messages" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    tree_mgr = ARINcli::Registration::TicketTreeManager.new c
    tree_mgr.sort_messages( ticket_node )
    assert_equal( ticket_node.children[ 0 ].handle, "3" )
    assert_equal( ticket_node.children[ 1 ].handle, "4" )
    assert_equal( ticket_node.children[ 2 ].handle, "1" )
    assert_equal( ticket_node.children[ 3 ].handle, "2" )
    assert_equal( ticket_node.children[ 4 ].handle, "5" )
  end

end
