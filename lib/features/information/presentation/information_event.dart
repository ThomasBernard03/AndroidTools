part of 'information_bloc.dart';

sealed class InformationEvent {}

class OnAppearing extends InformationEvent {}

class OnRefreshDevices extends InformationEvent {}
