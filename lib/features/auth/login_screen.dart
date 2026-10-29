import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AuthService _authService;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLoginMode && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Mật khẩu xác nhận không trùng khớp. Vui lòng kiểm tra lại!'),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('🎉 Đăng nhập thành công! Chào mừng bạn quay trở lại.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }

        // Bắn thông báo hệ thống về điện thoại
        await NotificationService().showLocalNotification(
          id: 1001,
          title: '🎉 Đăng nhập thành công',
          body: 'Chào mừng bạn quay trở lại MiniSocial!',
        );
      } else {
        await _authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('🎉 Tạo tài khoản thành công! Chào mừng bạn đến với MiniSocial.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }

        // Bắn thông báo hệ thống về điện thoại
        await NotificationService().showLocalNotification(
          id: 1002,
          title: '🎉 Đăng ký thành công',
          body: 'Tài khoản của bạn đã được khởi tạo thành công trên MiniSocial!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e.toString().replaceAll('Exception: ', '')),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập email của bạn để nhận liên kết khôi phục mật khẩu.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi email khôi phục mật khẩu nếu tài khoản tồn tại.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGO BRANDING WITH GRADIENT
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, const Color(0xFF818CF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bubble_chart_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'MiniSocial',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoginMode
                          ? 'Mạng xã hội kết nối bạn bè & gia đình'
                          : 'Đăng ký tài khoản trải nghiệm ngay',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // TOGGLE TAB LOGIN / REGISTER
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_isLoginMode) {
                                  setState(() => _isLoginMode = true);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isLoginMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isLoginMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  'Đăng nhập',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: _isLoginMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _isLoginMode
                                        ? primaryColor
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_isLoginMode) {
                                  setState(() => _isLoginMode = false);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isLoginMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isLoginMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  'Đăng ký',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: !_isLoginMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !_isLoginMode
                                        ? primaryColor
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // FORM FIELDS
                    if (!_isLoginMode) ...[
                      TextFormField(
                        key: const ValueKey('name_field'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Tên hiển thị',
                          hintText: 'Nguyễn Văn A',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (!_isLoginMode) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên hiển thị';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      key: const ValueKey('email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ Email',
                        hintText: 'example@gmail.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      key: const ValueKey('password_field'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mật khẩu phải từ 6 ký tự trở lên';
                        }
                        return null;
                      },
                    ),

                    if (!_isLoginMode) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('confirm_password_field'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (!_isLoginMode) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng xác nhận lại mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không trùng khớp';
                            }
                          }
                          return null;
                        },
                      ),
                    ],

                    if (_isLoginMode) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                    ],

                    // SUBMIT BUTTON
                    FilledButton(
                      key: const ValueKey('submit_button'),
                      onPressed: _isLoading ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shadowColor: primaryColor.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'Đăng nhập ngay' : 'Tạo tài khoản mới',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
