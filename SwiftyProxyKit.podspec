Pod::Spec.new do |s|

    s.name                  = 'SwiftyProxyKit'
    s.version               = '0.1'
    s.summary               = 'Local HTTP Server for iOS and OS X that can be used as a proxy server.'
    s.homepage              = 'https://github.com/abdullahselek/SwiftyProxyKit'
    s.license               = {
        :type => 'MIT',
        :file => 'LICENSE'
    }
    s.author                = {
        'Abdullah Selek' => 'abdullahselek@gmail.com'
    }
    s.source                = {
        :git => 'https://github.com/abdullahselek/SwiftyProxyKit.git',
        :tag => s.version.to_s
    }
    s.ios.deployment_target = '9.0'
    s.source_files          = 'SwiftyProxyKit/**/*.swift'
    s.requires_arc          = true

end
