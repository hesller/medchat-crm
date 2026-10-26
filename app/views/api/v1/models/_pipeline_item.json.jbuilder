conversation = item.conversation
json.id item.id
json.pipeline_stage_id item.pipeline_stage_id
json.position item.position
json.conversation do
  json.id conversation.display_id
  json.status conversation.status
  json.last_activity_at conversation.last_activity_at.to_i
  json.inbox_name conversation.inbox.name
  json.contact do
    json.id conversation.contact.id
    json.name conversation.contact.name
    json.thumbnail conversation.contact.avatar_url
  end
  if conversation.assignee
    json.assignee do
      json.id conversation.assignee.id
      json.name conversation.assignee.available_name
      json.thumbnail conversation.assignee.avatar_url
    end
  else
    json.assignee nil
  end
end
