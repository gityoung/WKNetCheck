

Pod::Spec.new do |spec|


  spec.name         = "WKNetCheck"
  spec.version      = "0.0.2"
  spec.ios.deployment_target = '8.0'
  spec.summary      = "A Net Info of Tools."

  spec.homepage     = "https://github.com/gityoung/WKNetCheck"

  spec.license      = "MIT"
  spec.author             = { "young" => "" }
  
  spec.source       = { 
  	:git => "https://github.com/gityoung/WKNetCheck.git", 
  	:tag => "#{spec.version}" 
  }

  spec.source_files  = "WKNetCheck/*/*.{h,m}"
   spec.requires_arc = true

end
