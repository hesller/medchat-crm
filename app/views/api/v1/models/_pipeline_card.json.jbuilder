json.id card.id
json.pipeline_id card.pipeline_id
json.pipeline_stage_id card.pipeline_stage_id
json.title card.title
json.description card.description
json.value card.value&.to_f
json.position card.position
json.contact do
  if card.contact
    json.id card.contact.id
    json.name card.contact.name
    json.thumbnail card.contact.avatar_url
  else
    json.nil!
  end
end
json.assignee do
  if card.assignee
    json.id card.assignee.id
    json.name card.assignee.available_name
    json.thumbnail card.assignee.avatar_url
  else
    json.nil!
  end
end
json.created_at card.created_at.to_i
json.updated_at card.updated_at.to_i
