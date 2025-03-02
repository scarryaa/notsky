import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/profile/presentation/cubits/post_state.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.actorDid});

  final String actorDid;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();

    context.read<ProfileCubit>().getProfile(widget.actorDid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return _buildProfile(state);
        } else if (state is ProfileError) {
          return Center(
            child: Text('Error: could not load profile. ${state.message}'),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildProfile(ProfileLoaded state) {
    return Image.network(state.profile.banner ?? '');
  }
}
