import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import '../../shared/widgets/request_state.dart';
import '../../shared/widgets/auth_guard.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _api = ApiClient();
  UserModel? _user;
  List<PostModel> _posts = [];
  bool _loading = true, _busy = false, _isOwn = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_api.getUserProfile(widget.userId), _api.getUserPosts(widget.userId), _api.getCurrentUser()]);
      if (!mounted) return;
      setState(() { _user = results[0] as UserModel?; _posts = results[1] as List<PostModel>; _isOwn = (results[2] as UserModel?)?.id == widget.userId; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = ApiClient.errorMessage(e); _loading = false; }); }
  }

  String _url(String value) => Uri.tryParse(value)?.hasScheme == true ? value : '${ApiConstants.hostUrl}/${value.replaceFirst(RegExp(r'^/'), '')}';

  Future<void> _follow() async {
    if (!await requireSession(context) || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final following = await _api.toggleFollow(widget.userId);
      if (mounted) setState(() {
        _user!.isFollowing = following;
        _user!.followersCount =
            (_user!.followersCount + (following ? 1 : -1)).clamp(0, 1 << 31) as int;
      });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e)))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil ciudadano')),
    body: _loading ? Center(child: CircularProgressIndicator(color: context.loveColor)) : _error != null ? RequestState(message: _error!, onRetry: _load) : RefreshIndicator(
      color: context.loveColor, onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), children: [
        Row(children: [
          Container(width: 82,height:82,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(shape:BoxShape.circle,color:context.surfaceColor,border:Border.all(color:context.borderColor,width:2)),child:_user!.avatarUrl?.isNotEmpty==true?Image.network(_url(_user!.avatarUrl!),fit:BoxFit.cover):Icon(Icons.person_rounded,size:42,color:context.loveColor)),
          const SizedBox(width:16), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Flexible(child:Text(_user!.displayName,style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:context.textPrimaryColor))),if(_user!.isVerified)...[const SizedBox(width:5),Icon(Icons.verified_rounded,color:context.pineColor,size:20)]]),Text('@${_user!.username}',style:TextStyle(color:context.subtleColor)),const SizedBox(height:10),if(!_isOwn)SizedBox(height:40,child:FilledButton(onPressed:_busy?null:_follow,child:Text(_user!.isFollowing?'Siguiendo':'Seguir')))]))
        ]),
        const SizedBox(height:20),
        Container(padding:const EdgeInsets.symmetric(vertical:14),decoration:BoxDecoration(color:context.surfaceColor,borderRadius:BorderRadius.circular(18),border:Border.all(color:context.borderColor,width:2)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[_stat('${_posts.length}','Publicaciones'),_stat('${_user!.followersCount}','Seguidores'),_stat('${_user!.followingCount}','Siguiendo')])),
        const SizedBox(height:22), Text('Publicaciones',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:context.textPrimaryColor)),const SizedBox(height:8),
        if(_posts.isEmpty)Padding(padding:const EdgeInsets.all(32),child:Text('Este perfil todavía no ha publicado incidencias.',textAlign:TextAlign.center,style:TextStyle(color:context.subtleColor))) else ..._posts.map((p)=>IncidentCard(key:ValueKey(p.id),post:p)),
      ])));

  Widget _stat(String value,String label)=>Column(children:[Text(value,style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:context.textPrimaryColor)),Text(label,style:TextStyle(fontSize:11,color:context.subtleColor))]);
}
