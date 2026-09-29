import 'package:flutter/material.dart';
import '../core/networking/api_client.dart';
import '../core/theme/app_theme.dart';
import '../shared/models/models.dart';
import 'feed/post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState()=>_NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen>{
  final _api=ApiClient(); List<NotificationModel> _items=[]; bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{try{final items=await _api.getNotifications();await _api.markNotificationsRead();if(mounted)setState((){_items=items;_loading=false;});}catch(_){if(mounted)setState(()=>_loading=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Notificaciones')),body:_loading?Center(child:CircularProgressIndicator(color:context.loveColor)):RefreshIndicator(color:context.loveColor,onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(12,8,12,40),physics:const AlwaysScrollableScrollPhysics(),children:[if(_items.isEmpty)Padding(padding:const EdgeInsets.all(48),child:Column(children:[Icon(Icons.notifications_none_rounded,size:48,color:context.mutedColor),const SizedBox(height:12),Text('Todavía no tienes notificaciones.',style:TextStyle(color:context.subtleColor))]))else ..._items.map((n)=>Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:context.surfaceColor,borderRadius:BorderRadius.circular(16),border:Border.all(color:n.isRead?context.borderColor:context.loveColor,width:2)),child:ListTile(leading:Icon(Icons.campaign_rounded,color:context.loveColor),title:Text(n.message),subtitle:Text('${n.createdAt.toLocal().day}/${n.createdAt.toLocal().month}/${n.createdAt.toLocal().year}'),trailing:const Icon(Icons.chevron_right_rounded),onTap:n.postId==null?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PostDetailScreen(postId:n.postId!))))))])));
}
