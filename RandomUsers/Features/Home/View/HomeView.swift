import SwiftUI

struct HomeView: View {
    
    @ObservedObject private var viewModel: HomeVM
    
    init(viewModel: HomeVM) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.users, id: \.email) { user in
                    ZStack {
                        UserItemListView(user: user)
                        NavigationLink(destination: UserView(user: user)) {
                        }
                        .buttonStyle(PlainButtonStyle()).frame(width:0).opacity(0)
                    }
                    .task {
                        if viewModel.mustLoadMoreUsers(from: user) {
                            await viewModel.loadUsers()
                        }
                    }
                    .listRowSeparator(.hidden)
                    .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
                }
                .onDelete(perform: { indexSet in
                    viewModel.delete(at: indexSet)
                })
            }
            .listStyle(.plain)
            .refreshable {
                Task {
                    await viewModel.loadUsers()
                }
            }
            .navigationTitle("home_view_title")
        }
        .alert(isPresented: $viewModel.showWarning, content: {
            let localizedString = NSLocalizedString("warning_title", comment: "").uppercased()
            return Alert(title: Text(localizedString), message: Text(viewModel.showWarningMessage))
        })
        .task {
            await viewModel.loadUsers()
        }
        .searchable(text: $viewModel.usersSearchText, prompt: "search_prompt")
        .autocorrectionDisabled()
        .autocapitalization(.none)
        .onChange(of: viewModel.usersSearchText, { _, newValue in
            viewModel.resetUsers()
            viewModel.usersSearchText = newValue
            viewModel.loadUsersDebounced()
        })
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: HomeVM(networkService: RandomUsersNetworkService(httpClient: URLSessionHTTPClient())))
    }
}
