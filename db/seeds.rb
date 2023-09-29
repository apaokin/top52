# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

Group.superadmins
Group.authorized
admin = User.create!(email: "admin@octoshell.ru",
                            access_state: 'active',
                            password: "123456",
                            password_confirmation: '123456')
admin.activate!
admin.groups << Group.superadmins
