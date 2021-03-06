import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gank/api//api_gank.dart';
import 'package:flutter_gank/common/event/event_change_column.dart';
import 'package:flutter_gank/common/manager/app_manager.dart';
import 'package:flutter_gank/common/model/gank_item.dart';
import 'package:flutter_gank/common/utils/common_utils.dart';
import 'package:flutter_gank/common/utils/time_utils.dart';
import 'package:flutter_gank/ui/page/page_gallery.dart';
import 'package:flutter_gank/ui/widget/indicator_factory.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class WelfarePage extends StatefulWidget {
  @override
  _WelfarePageState createState() => _WelfarePageState();
}

class _WelfarePageState extends State<WelfarePage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  List _gankItems = [];
  int _page = 1;
  bool isOneColumn = true;
  RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    AppManager.eventBus.on<ChangeWelfareColumnEvent>().listen((event) {
      if (mounted) {
        setState(() {
          isOneColumn = !isOneColumn;
        });
      }
    });
    _refreshController = new RefreshController();
    _getCategoryData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.white,
      child: Stack(
        children: <Widget>[
          Offstage(
              offstage: _isLoading,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: SmartRefresher(
                  controller: _refreshController,
                  headerBuilder: buildDefaultHeader,
                  footerBuilder: (context, mode) =>
                      buildDefaultFooter(context, mode, () {
                        _refreshController.sendBack(
                            false, RefreshStatus.refreshing);
                      }),
                  onRefresh: _onRefresh,
                  enablePullUp: true,
                  child: GridView.count(
                    //横轴的最大长度
                    crossAxisCount: isOneColumn ? 1 : 2,
                    //主轴间隔
                    mainAxisSpacing: 10.0,
                    //横轴间隔
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 2 / (isOneColumn ? 2 : 3),
                    children: _gankItems?.map<Widget>((gankItem) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return GalleryPage([
                                  (gankItem.url as String)
                                      .replaceFirst("large", "mw690")
                                ], gankItem.desc);
                              }));
                            },
                            child: _buildImageWidget(gankItem),
                          );
                        })?.toList() ??
                        [],
                  ),
                ),
              )),
          Offstage(
            offstage: !_isLoading,
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImageWidget(gankItem) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
              child: isOneColumn
                  ? CachedNetworkImage(
                      imageUrl: gankItem.url,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: gankItem.url,
                      fit: BoxFit.cover,
                    )),
          Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width - 20,
                color: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      formatDateStr(gankItem.publishedAt),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ))
        ],
      ),
    );
  }

  void _onRefresh(bool up) {
    if (!up) {
      _page++;
      _getCategoryData(loadMore: true);
    } else {
      _page = 1;
      _getCategoryData();
    }
  }

  void _getCategoryData({bool loadMore = false}) async {
    var categoryData = await GankApi.getCategoryData('福利', _page);
    var gankItems = categoryData['results']
        .map<GankItem>((itemJson) => GankItem.fromJson(itemJson,
            category: CommonUtils.getLocale(context).gankWelfare))
        .toList();
    if (loadMore) {
      _refreshController.sendBack(false, RefreshStatus.idle);
      setState(() {
        _gankItems.addAll(gankItems);
        _isLoading = false;
      });
    } else {
      _refreshController.sendBack(true, RefreshStatus.completed);
      setState(() {
        _gankItems = gankItems;
        _isLoading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
