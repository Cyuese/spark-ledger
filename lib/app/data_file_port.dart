export 'data_file_port_stub.dart'
    if (dart.library.html) 'data_file_port_web.dart'
    if (dart.library.io) 'data_file_port_io.dart';
