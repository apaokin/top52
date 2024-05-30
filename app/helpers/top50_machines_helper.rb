module Top50MachinesHelper
  def custom_word_wrap(text, max_width=15)
    return nil if text.blank?
    (text.length < max_width) ?
    text :
    text.scan(/.{1,#{max_width}}/).join("\n")
  end
  def get_max_branch_size(cluster)
    max = 0
    cluster.each do |id|
      machine = Top50Machine.find_by(id: id)
      if get_branch_size(machine) > max
        max = get_branch_size(machine)
      end
    end

    return max
  end

  def get_branch_size(machine)
    mod = machine.modification
    size = 1
    while nil != mod do
      size += 1
      mod = mod.modification
    end

    return size
  end

  def get_contact_str(machine)
    if machine.contact_id == nil
      return "Не указан"
    end
    contact_id = machine.contact_id
    contact = Top50Contact.find_by(id: contact_id)
    contact_str = "#{contact.surname}"
    if contact.name != nil and contact.name != ""
      contact_str = "#{contact_str} #{contact.name[0]}."
      if contact.patronymic != nil and contact.patronymic != ""
        contact_str = "#{contact_str} #{contact.patronymic[0]}."
      end
    end

    return contact_str
  end

  def get_vendors_names(machine)
    vendors_str = ""
    machine.vendor_ids.each do |vendor_id|
      vendors_str += Top50Vendor.find_by(id: vendor_id).name + " "
    end

    return vendors_str
  end

  def get_org_name(machine)
    if machine.org_id == nil
      return "   "
    end

    org_id = machine.org_id
    org = Top50Organization.find_by(id: org_id)
    return org.name
  end

  def format_valid_flag(machine)
    valid = machine.is_valid
    if valid == 0
      return "Отклонена"
    elsif valid == 1
      return "Одобрена"
    elsif valid == 2
      return "Не рассмотрена"
    else
      return "Ошибка!"
    end
  end

  def get_status_classname(machine)
    valid = machine.is_valid
    classname = "colored_line "
    if valid == 0
      return classname + "non_valid"
    elsif valid == 1
      return classname + "valid"
    elsif valid == 2
      return classname + "new"
    else
      return classname + "error"
    end
  end

end
