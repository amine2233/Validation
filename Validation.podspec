Pod::Spec.new do |s|
    s.name 				        = "Validation"
    s.version 			        = "0.1"
    s.summary         	        = "Validation element inspired by validation vapor"
    s.homepage        	        = "https://github.com/amine2233/Validation"
    s.license                   = { type: "MIT", file: "LICENSE" }
    s.author                    = { 'Amine Bensalah' => 'amine.bensalah@outlook.com' }
    s.ios.deployment_target     = "13.0"
    s.osx.deployment_target     = "10.15"
    s.tvos.deployment_target    = "13.0"
    s.watchos.deployment_target = "6.0"
    s.requires_arc              = true
    s.source                    = { :git => "https://github.com/amine2233/Validation.git", :tag => s.version.to_s }
    s.source_files              = "Sources/**/*.swift"
    s.exclude_files		        = "LICENSE"
    s.swift_version             = "5.0"
    s.module_name               = s.name
    s.pod_target_xcconfig = {
        'SWIFT_VERSION' => s.swift_version
    }

    s.test_spec 'Tests' do |test_spec|
        test_spec.platform = :ios, "13.0"
        test_spec.platform = :tvos, "13.0"
        test_spec.platform = :macos, "10.15"
        test_spec.source_files  = "Tests/**/*.swift"
    end
end