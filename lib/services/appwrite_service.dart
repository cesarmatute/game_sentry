import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static final Client client = Client()
    ..setEndpoint('https://nyc.cloud.appwrite.io/v1') // your Appwrite endpoint
    ..setProject('68ac6b7600141d9fe1d9'); // your Project ID

  static final Databases db = Databases(client);
  static final Realtime realtime = Realtime(client);
  static final Account account = Account(client);
}