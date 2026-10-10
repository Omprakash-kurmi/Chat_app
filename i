{
  "ignored_warnings": [
    {
      "warning_type": "Cross-Site Scripting",
      "warning_code": 4,
      "fingerprint": "8a162dba76e00dbd4108154767ebadabe02da8f45fb344525c6d77373c01bd8e",
      "check_name": "LinkToHref",
      "message": "Potentially unsafe model attribute in `link_to` href",
      "file": "app/views/devise/shared/_footer.html.erb",
      "line": 23,
      "link": "https://brakemanscanner.org/docs/warning_types/link_to_href",
      "code": "link_to((Unresolved Model).new.platform, (Unresolved Model).new.url, :target => \"_blank\", :rel => \"noopener\", :title => (Unresolved Model).new.platform)",
      "render_path": [
        {
          "type": "controller",
          "class": "ApplicationController",
          "method": "configure_permitted_parameters",
          "line": 10,
          "file": "app/controllers/application_controller.rb",
          "rendered": {
            "name": "layouts/application",
            "file": "app/views/layouts/application.html.erb"
          }
        },
        {
          "type": "template",
          "name": "layouts/application",
          "line": 33,
          "file": "app/views/layouts/application.html.erb",
          "rendered": {
            "name": "devise/shared/_footer",
            "file": "app/views/devise/shared/_footer.html.erb"
          }
        }
      ],
      "location": {
        "type": "template",
        "template": "devise/shared/_footer"
      },
      "user_input": "(Unresolved Model).new.url",
      "confidence": "Weak",
      "cwe_id": [
        79
      ],
      "note": ""
    },
    {
      "warning_type": "Unmaintained Dependency",
      "warning_code": 120,
      "fingerprint": "d84924377155b41e094acae7404ec2e521629d86f97b0ff628e3d1b263f8101c",
      "check_name": "EOLRails",
      "message": "Support for Rails 7.2.3.2 ended on 2026-08-09",
      "file": "Gemfile.lock",
      "line": 345,
      "link": "https://brakemanscanner.org/docs/warning_types/unmaintained_dependency/",
      "code": null,
      "render_path": null,
      "location": null,
      "user_input": null,
      "confidence": "High",
      "cwe_id": [
        1104
      ],
      "note": ""
    }
  ],
  "brakeman_version": "8.1.0"
}
