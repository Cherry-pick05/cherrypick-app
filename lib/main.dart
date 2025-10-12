import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //home: Text('안녕')  //글씨 위젯
      //home: Icon(Icons.shop)  //아이콘 위젯. 플러터 홈페이지에서 아이콘 이름 찾아보기
      //home: Image.asset('assets/roi.png')  //이미지 위젯
      //home: Container( width:50, height:50, color: Colors.blue)  //박스 위젯

      // home: Center(
      //   child: Container( width:50, height:50, color: Colors.blue )
      // )
        home: Scaffold(
          appBar: AppBar(),  //상단에 들어갈 위젯
          body: Container(),
          bottomNavigationBar: BottomAppBar( child: Text('gkgk') ),
        )  //Scaffold
    );
  }
}
