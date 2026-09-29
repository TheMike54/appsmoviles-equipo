# Genera CamaraMicrofono.xcodeproj a partir de los archivos .swift de las carpetas
# CamaraMicrofono/ (app) y CamaraMicrofonoUITests/ (pruebas de interfaz).
# Uso (en macOS, dentro de esta carpeta):  ruby generar_proyecto.rb
# Requiere la gema xcodeproj (viene con CocoaPods). El .xcodeproj generado se versiona,
# así que para abrir o compilar el proyecto no hace falta correr este script.
require 'xcodeproj'

NOMBRE = 'CamaraMicrofono'
PRUEBAS = "#{NOMBRE}UITests"
proyecto = Xcodeproj::Project.new("#{NOMBRE}.xcodeproj")

def agregar_fuentes(proyecto, target, carpeta)
  grupo = proyecto.main_group.new_group(carpeta, carpeta)
  fuentes = Dir.glob("#{carpeta}/**/*.swift").sort.map { |ruta| grupo.new_file(ruta.sub("#{carpeta}/", '')) }
  target.add_file_references(fuentes)
  [grupo, fuentes.size]
end

# App
app = proyecto.new_target(:application, NOMBRE, :ios, '17.0')
grupo_app, total_app = agregar_fuentes(proyecto, app, NOMBRE)
grupo_app.new_file('Info.plist')
app.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'mx.ipn.escom.CamaraMicrofono'
  s['PRODUCT_NAME'] = NOMBRE
  s['INFOPLIST_FILE'] = "#{NOMBRE}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  s['MARKETING_VERSION'] = '1.0'
  s['CURRENT_PROJECT_VERSION'] = '1'
  s['CODE_SIGN_STYLE'] = 'Automatic'
end

# Pruebas de interfaz (XCUITest)
pruebas = proyecto.new_target(:ui_test_bundle, PRUEBAS, :ios, '17.0')
_, total_pruebas = agregar_fuentes(proyecto, pruebas, PRUEBAS)
pruebas.add_dependency(app)
pruebas.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'mx.ipn.escom.CamaraMicrofonoUITests'
  s['PRODUCT_NAME'] = PRUEBAS
  s['TEST_TARGET_NAME'] = NOMBRE
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  s['CODE_SIGN_STYLE'] = 'Automatic'
end

proyecto.save

esquema = Xcodeproj::XCScheme.new
esquema.configure_with_targets(app, pruebas, launch_target: true)
esquema.save_as(proyecto.path, NOMBRE, true)
puts "Proyecto #{NOMBRE}.xcodeproj generado: #{total_app} archivos de la app, #{total_pruebas} de pruebas"
